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
    final occupants = tokensAt(state, dest)
        .where((t) => t.playerId != mover.playerId)
        .toList();
    if (occupants.isEmpty) {
      return false;
    }
    final byPlayer = <String, int>{};
    for (final token in occupants) {
      byPlayer[token.playerId] = (byPlayer[token.playerId] ?? 0) + 1;
    }
    return byPlayer.values.any((count) => count >= 2);
  }

  static List<TokenState> tokensAt(GameState state, BoardPosition position) {
    if (position is HomePosition || position is BasePosition) {
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
    final opponents = tokensAt(state, dest)
        .where((t) => t.playerId != mover.playerId)
        .toList();
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
    return false;
  }

  static bool isWinner(GameState state, String playerId) {
    final tokens = state.tokensFor(playerId);
    if (tokens.length != BoardConstants.tokensPerPlayer) {
      return false;
    }
    return tokens.every((t) => t.state == TokenLogicalState.home);
  }

  static PlayerColor? nextOccupiedColor(
    GameState state,
    PlayerColor current,
  ) {
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
}
