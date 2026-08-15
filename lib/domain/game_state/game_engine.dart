import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../services/dice_service.dart';
import '../models/game_state.dart';
import '../rules/board_map.dart';
import '../rules/game_rules.dart';
import '../rules/movement.dart';

class EngineResult {
  const EngineResult({
    required this.state,
    this.events = const [],
  });

  final GameState state;
  final List<EngineEvent> events;
}

sealed class EngineEvent {
  const EngineEvent();
}

class DiceRolledEvent extends EngineEvent {
  const DiceRolledEvent({
    required this.playerId,
    required this.value,
    required this.turnId,
    required this.forfeited,
  });

  final String playerId;
  final int value;
  final String turnId;
  final bool forfeited;
}

class ValidMovesEvent extends EngineEvent {
  const ValidMovesEvent(this.tokenIds);
  final List<String> tokenIds;
}

class TokenMovedEvent extends EngineEvent {
  const TokenMovedEvent({
    required this.tokenId,
    required this.from,
    required this.to,
    required this.path,
  });

  final String tokenId;
  final BoardPosition from;
  final BoardPosition to;
  final List<BoardPosition> path;
}

class TokenCapturedEvent extends EngineEvent {
  const TokenCapturedEvent({
    required this.tokenId,
    required this.byTokenId,
  });

  final String tokenId;
  final String byTokenId;
}

class TokenReachedHomeEvent extends EngineEvent {
  const TokenReachedHomeEvent(this.tokenId);
  final String tokenId;
}

class TurnChangedEvent extends EngineEvent {
  const TurnChangedEvent({
    required this.playerId,
    required this.turnId,
    required this.turnNumber,
    this.reason,
  });

  final String playerId;
  final String turnId;
  final int turnNumber;
  final String? reason;
}

class PlayerWonEvent extends EngineEvent {
  const PlayerWonEvent(this.playerId);
  final String playerId;
}

class GameFinishedEvent extends EngineEvent {
  const GameFinishedEvent(this.winnerId);
  final String winnerId;
}

/// Pure, host-side rules engine. Flame must never call this.
class GameEngine {
  GameEngine({required DiceService diceService, Uuid? uuid})
      : _dice = diceService,
        _uuid = uuid ?? const Uuid();

  final DiceService _dice;
  final Uuid _uuid;

  GameState addPlayer(GameState state, PlayerState player) {
    _assertLobby(state);
    if (state.players.length >= BoardConstants.maxPlayers) {
      throw GameException(GameErrorCode.gameFull, 'Game is full');
    }
    if (state.players.any((p) => p.color == player.color)) {
      throw GameException(GameErrorCode.colorTaken, 'Color already taken');
    }
    if (state.players.any((p) => p.playerId == player.playerId)) {
      throw GameException(GameErrorCode.unknownPlayer, 'Player already joined');
    }
    final players = [...state.players, player];
    return state.copyWith(
      players: players,
      tokens: GameState.tokensForPlayers(players),
    ).bumped();
  }

  GameState removePlayer(GameState state, String playerId) {
    final players =
        state.players.where((p) => p.playerId != playerId).toList();
    final tokens =
        state.tokens.where((t) => t.playerId != playerId).toList();
    var next = state.copyWith(players: players, tokens: tokens).bumped();
    if (state.status == GameStatus.active &&
        state.currentPlayerId == playerId &&
        next.players.where((p) => p.isConnected || p.isAi).isNotEmpty) {
      next = _advanceTurn(next, reason: 'player_left').state;
    }
    return next;
  }

  GameState setReady(GameState state, String playerId, bool ready) {
    _assertLobby(state);
    return _updatePlayer(state, playerId, (p) => p.copyWith(isReady: ready))
        .bumped();
  }

  GameState claimColor(GameState state, String playerId, PlayerColor color) {
    _assertLobby(state);
    if (state.players.any((p) => p.color == color && p.playerId != playerId)) {
      throw GameException(GameErrorCode.colorTaken, 'Color already taken');
    }
    final updated = _updatePlayer(
      state,
      playerId,
      (p) => p.copyWith(color: color),
    );
    return updated
        .copyWith(tokens: GameState.tokensForPlayers(updated.players))
        .bumped();
  }

  GameState setAiEnabled(GameState state, bool enabled) {
    _assertLobby(state);
    return state.copyWith(aiEnabled: enabled).bumped();
  }

  GameState markConnected(GameState state, String playerId, bool connected) {
    var next = _updatePlayer(
      state,
      playerId,
      (p) => p.copyWith(isConnected: connected),
    );
    if (state.status == GameStatus.active &&
        !connected &&
        state.currentPlayerId == playerId) {
      next = _advanceTurn(next, reason: 'disconnect').state;
    }
    return next.bumped();
  }

  GameState returnToLobby(GameState state) {
    final players = [
      for (final player in state.players)
        if (!player.isAi)
          player.copyWith(isReady: false, clearRank: true),
    ];
    if (players.isEmpty) {
      throw GameException(GameErrorCode.notEnoughPlayers, 'No players remain');
    }
    return GameState(
      gameId: state.gameId,
      status: GameStatus.lobby,
      players: players,
      tokens: GameState.tokensForPlayers(players),
      currentPlayerId: null,
      turnNumber: 0,
      diceValue: null,
      diceRolled: false,
      consecutiveSixes: 0,
      validMoves: const [],
      winnerId: null,
      revision: state.revision + 1,
      turnId: 't0',
      phase: TurnPhase.waitingForRoll,
      aiEnabled: state.aiEnabled,
      lastCaptureTokenId: null,
      finishedOrder: const [],
    );
  }

  EngineResult startGame(GameState state) {
    _assertLobby(state);
    var players = [...state.players];
    if (state.aiEnabled) {
      players = _fillAi(players);
    }
    final humansAndAi = players.where((p) => p.isConnected || p.isAi).toList();
    if (humansAndAi.length < BoardConstants.minPlayers) {
      throw GameException(
        GameErrorCode.notEnoughPlayers,
        'Need at least ${BoardConstants.minPlayers} players',
      );
    }
    if (!players.where((p) => !p.isAi).every((p) => p.isReady)) {
      throw GameException(GameErrorCode.notReady, 'All players must be ready');
    }

    final firstColor = BoardConstants.turnOrder.firstWhere(
      (c) => players.any((p) => p.color == c),
    );
    final firstId = players.firstWhere((p) => p.color == firstColor).playerId;
    final turnId = _uuid.v4();
    final started = state.copyWith(
      status: GameStatus.active,
      players: players,
      tokens: GameState.tokensForPlayers(players),
      currentPlayerId: firstId,
      turnNumber: 1,
      diceRolled: false,
      consecutiveSixes: 0,
      validMoves: const [],
      phase: TurnPhase.waitingForRoll,
      turnId: turnId,
      clearDiceValue: true,
      clearWinner: true,
      clearLastCapture: true,
      forfeitedSixes: false,
      finishedOrder: const [],
    ).bumped();

    return EngineResult(
      state: started,
      events: [
        TurnChangedEvent(
          playerId: firstId,
          turnId: turnId,
          turnNumber: 1,
        ),
      ],
    );
  }

  EngineResult rollDice(GameState state, String playerId) {
    _assertActive(state);
    _assertTurn(state, playerId);
    if (!state.canRoll) {
      throw GameException(
        GameErrorCode.invalidDiceRequest,
        'Rolling is not allowed right now',
      );
    }

    final value = _dice.secureRoll();
    if (value < 1 || value > 6) {
      throw GameException(
        GameErrorCode.invalidDiceRequest,
        'Dice service produced an invalid face',
      );
    }

    var consecutive = state.consecutiveSixes;
    if (value == 6) {
      consecutive += 1;
    } else {
      consecutive = 0;
    }

    final forfeited = consecutive >= RuleConstants.maxConsecutiveSixes;
    var next = state.copyWith(
      diceValue: value,
      diceRolled: true,
      consecutiveSixes: forfeited ? 0 : consecutive,
      forfeitedSixes: forfeited,
      lastCaptureTokenId: null,
      clearLastCapture: true,
    );

    final events = <EngineEvent>[
      DiceRolledEvent(
        playerId: playerId,
        value: value,
        turnId: state.turnId,
        forfeited: forfeited,
      ),
    ];

    if (forfeited) {
      final advanced = _advanceTurn(next, reason: 'three_sixes');
      return EngineResult(
        state: advanced.state,
        events: [...events, ...advanced.events],
      );
    }

    final moves = GameRules.validMoves(next);
    next = next.copyWith(
      validMoves: moves,
      phase: TurnPhase.waitingForMove,
    ).bumped();
    events.add(ValidMovesEvent(moves));

    if (moves.isEmpty) {
      final extra = GameRules.grantsExtraTurn(
        diceValue: value,
        captured: false,
        consecutiveSixes: next.consecutiveSixes,
      );
      if (extra) {
        next = _prepareExtraRoll(next);
        events.add(
          TurnChangedEvent(
            playerId: playerId,
            turnId: next.turnId,
            turnNumber: next.turnNumber,
            reason: 'extra_no_move',
          ),
        );
      } else {
        final advanced = _advanceTurn(next, reason: 'no_valid_move');
        next = advanced.state;
        events.addAll(advanced.events);
      }
    }

    return EngineResult(state: next, events: events);
  }

  EngineResult moveToken(GameState state, String playerId, String tokenId) {
    _assertActive(state);
    _assertTurn(state, playerId);
    if (!state.canMove) {
      throw GameException(
        GameErrorCode.invalidMove,
        'A move is not allowed right now',
      );
    }
    if (!state.validMoves.contains(tokenId)) {
      throw GameException(
        GameErrorCode.invalidMove,
        'Token is not a valid move',
      );
    }

    final token = state.tokenById(tokenId);
    if (token.playerId != playerId) {
      throw GameException(
        GameErrorCode.invalidMove,
        'Token is not owned by this player',
      );
    }

    final color = BoardMap.colorOf(token);
    final dice = state.diceValue!;
    final dest = TokenMovement.destination(
      color: color,
      current: token.position,
      dice: dice,
    );
    if (dest == null) {
      throw GameException(GameErrorCode.invalidMove, 'Illegal destination');
    }

    final path = BoardMap.walk(color: color, from: token.position, to: dest);
    final captured = GameRules.capturableAt(state, token, dest);
    var tokens = [...state.tokens];
    final events = <EngineEvent>[
      TokenMovedEvent(
        tokenId: tokenId,
        from: token.position,
        to: dest,
        path: path,
      ),
    ];

    final newState = dest is HomePosition
        ? TokenLogicalState.home
        : TokenLogicalState.active;
    tokens = [
      for (final t in tokens)
        if (t.tokenId == tokenId)
          t.copyWith(position: dest, state: newState)
        else
          t,
    ];

    if (dest is HomePosition) {
      events.add(TokenReachedHomeEvent(tokenId));
    }

    for (final victim in captured) {
      tokens = [
        for (final t in tokens)
          if (t.tokenId == victim.tokenId)
            t.copyWith(
              position: BoardPosition.base(slot: t.slot),
              state: TokenLogicalState.base,
            )
          else
            t,
      ];
      events.add(
        TokenCapturedEvent(tokenId: victim.tokenId, byTokenId: tokenId),
      );
    }

    var next = state.copyWith(
      tokens: tokens,
      validMoves: const [],
      lastCaptureTokenId: captured.isEmpty ? null : tokenId,
      clearLastCapture: captured.isEmpty,
      diceRolled: true,
    );

    if (GameRules.isWinner(next, playerId)) {
      final order = [...state.finishedOrder, playerId];
      final remaining = next.players
          .where((p) => !order.contains(p.playerId))
          .map((p) => p.playerId)
          .toList();
      final players = [
        for (final p in next.players)
          if (p.playerId == playerId)
            p.copyWith(rank: 1)
          else
            p,
      ];
      next = next.copyWith(
        status: GameStatus.finished,
        phase: TurnPhase.finished,
        winnerId: playerId,
        finishedOrder: [...order, ...remaining],
        players: players,
        currentPlayerId: playerId,
      ).bumped();
      events
        ..add(PlayerWonEvent(playerId))
        ..add(GameFinishedEvent(playerId));
      return EngineResult(state: next, events: events);
    }

    final extra = GameRules.grantsExtraTurn(
      diceValue: dice,
      captured: captured.isNotEmpty,
      consecutiveSixes: next.consecutiveSixes,
    );
    if (extra) {
      next = _prepareExtraRoll(next);
      events.add(
        TurnChangedEvent(
          playerId: playerId,
          turnId: next.turnId,
          turnNumber: next.turnNumber,
          reason: captured.isNotEmpty ? 'capture' : 'six',
        ),
      );
    } else {
      final advanced = _advanceTurn(next, reason: 'moved');
      next = advanced.state;
      events.addAll(advanced.events);
    }

    return EngineResult(state: next, events: events);
  }

  GameState rejectFabricatedDice(GameState state) {
    throw GameException(
      GameErrorCode.fabricatedDice,
      'Clients cannot submit dice results',
    );
  }

  GameState rejectFabricatedPosition(GameState state) {
    throw GameException(
      GameErrorCode.fabricatedPosition,
      'Clients cannot submit token positions',
    );
  }

  GameState _updatePlayer(
    GameState state,
    String playerId,
    PlayerState Function(PlayerState) update,
  ) {
    final index = state.players.indexWhere((p) => p.playerId == playerId);
    if (index < 0) {
      throw GameException(GameErrorCode.playerNotFound, 'Unknown player');
    }
    final players = [...state.players];
    players[index] = update(players[index]);
    return state.copyWith(players: players);
  }

  List<PlayerState> _fillAi(List<PlayerState> players) {
    final used = players.map((p) => p.color).toSet();
    final filled = [...players];
    for (final color in PlayerColor.values) {
      if (used.contains(color)) {
        continue;
      }
      filled.add(
        PlayerState(
          playerId: 'ai-${color.name}',
          name: 'CPU ${color.displayName}',
          color: color,
          isReady: true,
          isConnected: true,
          isHost: false,
          isAi: true,
          reconnectToken: '',
        ),
      );
    }
    return filled;
  }

  GameState _prepareExtraRoll(GameState state) {
    return state.copyWith(
      diceRolled: false,
      validMoves: const [],
      phase: TurnPhase.waitingForRoll,
      turnId: _uuid.v4(),
      forfeitedSixes: false,
    ).bumped();
  }

  EngineResult _advanceTurn(GameState state, {String? reason}) {
    final current = state.currentPlayer;
    if (current == null) {
      return EngineResult(state: state);
    }
    final nextColor = GameRules.nextOccupiedColor(state, current.color);
    if (nextColor == null) {
      return EngineResult(state: state);
    }
    final nextId = GameRules.playerIdForColor(state, nextColor)!;
    final turnId = _uuid.v4();
    final next = state.copyWith(
      currentPlayerId: nextId,
      turnNumber: state.turnNumber + 1,
      diceRolled: false,
      consecutiveSixes: 0,
      validMoves: const [],
      phase: TurnPhase.waitingForRoll,
      turnId: turnId,
      forfeitedSixes: false,
      clearLastCapture: true,
    ).bumped();
    return EngineResult(
      state: next,
      events: [
        TurnChangedEvent(
          playerId: nextId,
          turnId: turnId,
          turnNumber: next.turnNumber,
          reason: reason,
        ),
      ],
    );
  }

  void _assertLobby(GameState state) {
    if (state.status != GameStatus.lobby) {
      throw GameException(
        GameErrorCode.gameAlreadyStarted,
        'Game is not in lobby',
      );
    }
  }

  void _assertActive(GameState state) {
    if (state.status == GameStatus.finished) {
      throw GameException(GameErrorCode.gameFinished, 'Game is over');
    }
    if (state.status != GameStatus.active) {
      throw GameException(
        GameErrorCode.gameAlreadyStarted,
        'Game is not active',
      );
    }
  }

  void _assertTurn(GameState state, String playerId) {
    if (state.currentPlayerId != playerId) {
      throw GameException(
        GameErrorCode.notPlayersTurn,
        'Not this player\'s turn',
      );
    }
    final player = state.playerById(playerId);
    if (player == null || !player.isConnected) {
      throw GameException(
        GameErrorCode.disconnectedPlayer,
        'Player is not connected',
      );
    }
  }
}
