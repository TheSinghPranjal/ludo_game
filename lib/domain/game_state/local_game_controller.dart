import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../services/dice_service.dart';
import '../../networking/protocol/event_mapper.dart';
import '../../networking/protocol/messages.dart';
import '../models/game_state.dart';
import 'game_engine.dart';

/// In-process authoritative loop for pass-and-play. No sockets.
class LocalGameController {
  LocalGameController({
    required this.onMessage,
    DiceService? diceService,
    Uuid? uuid,
  }) : _dice = diceService ?? const SecureDiceService(),
       _uuid = uuid ?? const Uuid() {
    _engine = GameEngine(diceService: _dice, uuid: _uuid);
  }

  final void Function(ServerMessage message) onMessage;
  final DiceService _dice;
  final Uuid _uuid;
  late final GameEngine _engine;

  GameState? _state;
  Timer? _turnClock;
  String? _armedTurnId;
  var _actionGen = 0;

  GameState? get state => _state;

  void start({required List<PlayerState> players}) {
    dispose();
    if (players.length < BoardConstants.minPlayers ||
        players.length > BoardConstants.maxPlayers) {
      throw GameException(
        GameErrorCode.notEnoughPlayers,
        'Pass-and-play needs 2 to 4 players',
      );
    }
    final ready = [
      for (final player in players) player.copyWith(isReady: true),
    ];
    var lobby = GameState(
      gameId: _uuid.v4(),
      status: GameStatus.lobby,
      players: ready,
      tokens: GameState.tokensForPlayers(ready),
      turnNumber: 0,
      diceRolled: false,
      consecutiveSixes: 0,
      validMoves: const [],
      revision: 1,
      turnId: 't0',
      phase: TurnPhase.waitingForRoll,
      aiEnabled: false,
      mode: GameMode.passAndPlay,
    );
    final result = _engine.startGame(lobby);
    _commit(result);
    onMessage(GameStartMessage(game: result.state.toJson()));
  }

  void rollDice(String playerId) {
    final state = _state;
    if (state == null) {
      return;
    }
    _apply(() => _engine.rollDice(state, playerId));
  }

  void moveToken(String playerId, String tokenId) {
    final state = _state;
    if (state == null) {
      return;
    }
    _apply(() => _engine.moveToken(state, playerId, tokenId));
  }

  void playAgain() {
    if (_state == null) {
      return;
    }
    _actionGen++;
    final lobby = _engine.returnToLobby(_state!);
    final result = _engine.startGame(
      lobby.copyWith(
        players: [
          for (final player in lobby.players) player.copyWith(isReady: true),
        ],
      ),
    );
    _commit(result);
    onMessage(GameStartMessage(game: result.state.toJson()));
  }

  void dispose() {
    _actionGen++;
    _turnClock?.cancel();
    _turnClock = null;
    _state = null;
  }

  /// Runs an engine action; rule violations become ERROR messages instead of
  /// escaping into UI callbacks or timers.
  void _apply(EngineResult Function() action) {
    final EngineResult result;
    try {
      result = action();
    } on GameException catch (error) {
      onMessage(ErrorMessage(code: error.code.name, message: error.message));
      return;
    }
    _actionGen++;
    _commit(result);
  }

  void _commit(EngineResult result) {
    _state = result.state;
    for (final message in messagesFor(result)) {
      onMessage(message);
    }
    _armTurnClock();
    _scheduleSingleMove();
  }

  void _scheduleSingleMove() {
    final state = _state;
    if (state == null ||
        !state.canMove ||
        state.validMoves.length != 1 ||
        state.currentPlayerId == null) {
      return;
    }
    final gen = _actionGen;
    final tokenId = state.validMoves.single;
    final playerId = state.currentPlayerId!;
    // Let the dice finish spinning so players see what was rolled first.
    Timer(TimingConstants.diceAnimation + TimingConstants.autoMoveDelay, () {
      final current = _state;
      if (gen != _actionGen ||
          current == null ||
          !current.validMoves.contains(tokenId)) {
        return;
      }
      _apply(() => _engine.moveToken(current, playerId, tokenId));
    });
  }

  void _armTurnClock() {
    _turnClock?.cancel();
    final state = _state;
    if (state == null || state.status != GameStatus.active) {
      return;
    }
    _armedTurnId = state.turnId;
    _turnClock = Timer.periodic(const Duration(seconds: 1), (_) {
      _onTurnTick();
    });
  }

  void _onTurnTick() {
    final state = _state;
    if (state == null ||
        state.turnId != _armedTurnId ||
        state.status != GameStatus.active) {
      _turnClock?.cancel();
      return;
    }
    final ticked = _engine.tickTimer(state);
    _state = ticked;
    onMessage(
      TurnTimerUpdateMessage(
        secondsRemaining: ticked.turnTimerSecondsRemaining,
        turnId: ticked.turnId,
      ),
    );
    if (ticked.turnTimerSecondsRemaining > 0) {
      return;
    }
    _turnClock?.cancel();
    _apply(() => _engine.expireTurn(ticked));
  }
}
