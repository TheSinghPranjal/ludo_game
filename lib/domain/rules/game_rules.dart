import '../../core/constants.dart';
import '../models/game_state.dart';
import 'board_map.dart';
import 'movement.dart';

abstract final class GameRules {
  static List<String> validMoves(GameState state) {
    final playerId = state.currentPlayerId;
    final dice = state.diceValue;
    if (playerId == null || dice == null) {
      return const [];
    }
    final player = state.playerById(playerId);
    if (player == null) {
      return const [];
    }

    final movable = <String>[];
    for (final token in state.tokensFor(playerId)) {
      if (_canMoveToken(state, token, player.color, dice)) {
        movable.add(token.tokenId);
      }
    }
    return movable;
  }

  static bool _canMoveToken(
    GameState state,
    TokenState token,
    PlayerColor color,
    int dice,
  ) {
    final dest = TokenMovement.destination(
      color: color,
      current: token.position,
      dice: dice,
    );
    if (dest == null) {
      return false;
    }
    return !_isBlockedByOpponentStack(state, token, dest);
  }

  static bool _isBlockedByOpponentStack(
    GameState state,
    TokenState mover,
    BoardPosition dest,
  ) {
    if (dest is HomePosition || dest is BasePosition) {
      return false;
    }
    final occupants = tokensAt(
      state,
      dest,
    ).where((t) => t.playerId != mover.playerId).toList();
    if (occupants.isEmpty) {
      return false;
    }
    final byPlayer = <String, int>{};
    for (final token in occupants) {
      byPlayer[token.playerId] = (byPlayer[token.playerId] ?? 0) + 1;
    }
    return byPlayer.values.any((count) => count >= 2);
  }

  /// Tokens sharing a main-track square. Base, home path and home are private
  /// to each color (their positions are color-relative), so nothing meets there.
  static List<TokenState> tokensAt(GameState state, BoardPosition position) {
    if (position is! TrackPosition) {
      return const [];
    }
    return state.tokens.where((t) => t.position == position).toList();
  }

  static List<TokenState> capturableAt(
    GameState state,
    TokenState mover,
    BoardPosition dest,
  ) {
    if (BoardMap.isSafe(dest) || dest is HomePosition || dest is BasePosition) {
      return const [];
    }
    final opponents = tokensAt(
      state,
      dest,
    ).where((t) => t.playerId != mover.playerId).toList();
    if (opponents.isEmpty) {
      return const [];
    }
    final byPlayer = <String, List<TokenState>>{};
    for (final token in opponents) {
      byPlayer.putIfAbsent(token.playerId, () => []).add(token);
    }
    final captured = <TokenState>[];
    for (final group in byPlayer.values) {
      if (group.length == 1) {
        captured.add(group.single);
      }
    }
    return captured;
  }

  static bool grantsExtraTurn({
    required int diceValue,
    required bool captured,
    required int consecutiveSixes,
    bool reachedHome = false,
  }) {
    if (consecutiveSixes >= RuleConstants.maxConsecutiveSixes) {
      return false;
    }
    if (RuleConstants.extraTurnOnSix && diceValue == 6) {
      return true;
    }
    if (RuleConstants.extraTurnOnCapture && captured) {
      return true;
    }
    if (RuleConstants.extraTurnOnHome && reachedHome) {
      return true;
    }
    return false;
  }

  static bool isWinner(GameState state, String playerId) {
    final tokens = state.tokensFor(playerId);
    if (tokens.length != BoardConstants.tokensPerPlayer) {
      return false;
    }
    return tokens.every((t) => t.state == TokenLogicalState.home);
  }

  /// Total squares travelled by a player's tokens; used to rank non-winners.
  static int progressOf(GameState state, String playerId) {
    final player = state.playerById(playerId);
    if (player == null) {
      return 0;
    }
    final fullLap = BoardMap.stepsToHome(
      player.color,
      TrackPosition(BoardMap.startIndex(player.color)),
    )!;
    var total = 0;
    for (final token in state.tokensFor(playerId)) {
      final remaining = BoardMap.stepsToHome(player.color, token.position);
      if (remaining != null) {
        total += fullLap + 1 - remaining;
      }
    }
    return total;
  }

  static PlayerColor? nextOccupiedColor(GameState state, PlayerColor current) {
    final occupied = state.players
        .where((p) => p.isConnected || p.isAi)
        .map((p) => p.color)
        .toSet();
    if (occupied.isEmpty) {
      return null;
    }
    final order = BoardConstants.turnOrder;
    final start = order.indexOf(current);
    for (var i = 1; i <= order.length; i++) {
      final color = order[(start + i) % order.length];
      if (occupied.contains(color)) {
        return color;
      }
    }
    return current;
  }

  static String? playerIdForColor(GameState state, PlayerColor color) {
    for (final player in state.players) {
      if (player.color == color) {
        return player.playerId;
      }
    }
    return null;
  }

  /// Deterministic timeout choice: capture, then home, then leave base, then slot order.
  static String? pickAutoMove(GameState state) {
    final ids = [...state.validMoves]..sort();
    if (ids.isEmpty) {
      return null;
    }
    final player = state.currentPlayer;
    if (player == null || state.diceValue == null) {
      return ids.first;
    }
    String? capture;
    String? home;
    String? leaveBase;
    for (final id in ids) {
      final token = state.tokenById(id);
      final dest = TokenMovement.destination(
        color: player.color,
        current: token.position,
        dice: state.diceValue!,
      );
      if (dest == null) {
        continue;
      }
      if (capture == null && capturableAt(state, token, dest).isNotEmpty) {
        capture = id;
      }
      if (home == null && dest is HomePosition) {
        home = id;
      }
      if (leaveBase == null && token.position is BasePosition) {
        leaveBase = id;
      }
    }
    return capture ?? home ?? leaveBase ?? ids.first;
  }
}
