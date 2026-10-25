import '../../core/constants.dart';
import '../models/board_position.dart';
import '../models/player_color.dart';
import '../models/token_state.dart';

/// Logical board geometry. No pixel coordinates live here.
abstract final class BoardMap {
  static int startIndex(PlayerColor color) => BoardConstants.startIndex[color]!;

  static int approachIndex(PlayerColor color) =>
      BoardConstants.approachIndex[color]!;

  static bool isSafe(BoardPosition position) {
    if (position is TrackPosition) {
      return BoardConstants.safeTrackIndices.contains(position.index);
    }
    return false;
  }

  static (int col, int row) cellOf(PlayerColor color, BoardPosition position) {
    switch (position) {
      case BasePosition(:final slot):
        return BoardConstants.baseSlots[color]![slot];
      case TrackPosition(:final index):
        return BoardConstants.trackCells[index];
      case HomePathPosition(:final index):
        return BoardConstants.homePathCells[color]![index];
      case HomePosition():
        return switch (color) {
          PlayerColor.green => (6, 7),
          PlayerColor.yellow => (7, 6),
          PlayerColor.red => (7, 8),
          PlayerColor.blue => (8, 7),
        };
    }
  }

  static PlayerColor colorOf(TokenState token) =>
      PlayerColor.fromId(token.colorId);

  /// Steps remaining to HOME, or null if the token cannot finish from here
  /// (still in base).
  static int? stepsToHome(PlayerColor color, BoardPosition position) {
    switch (position) {
      case BasePosition():
        return null;
      case HomePosition():
        return 0;
      case HomePathPosition(:final index):
        return BoardConstants.homePathLength - index;
      case TrackPosition(:final index):
        final approach = approachIndex(color);
        final toApproach =
            (approach - index + BoardConstants.trackLength) %
            BoardConstants.trackLength;
        return toApproach + 1 + BoardConstants.homePathLength;
    }
  }

  static List<BoardPosition> walk({
    required PlayerColor color,
    required BoardPosition from,
    required BoardPosition to,
  }) {
    if (from == to) {
      return const [];
    }
    if (from is BasePosition) {
      return [to];
    }
    if (to is BasePosition || from is HomePosition) {
      return [to];
    }

    final steps = <BoardPosition>[];
    var cursor = from;
    var guard = 0;
    while (cursor != to && guard < 64) {
      cursor = _stepForward(color, cursor);
      steps.add(cursor);
      guard++;
    }
    return steps;
  }

  static BoardPosition _stepForward(PlayerColor color, BoardPosition from) {
    switch (from) {
      case BasePosition():
        return TrackPosition(startIndex(color));
      case HomePosition():
        return from;
      case HomePathPosition(:final index):
        if (index + 1 >= BoardConstants.homePathLength) {
          return const HomePosition();
        }
        return HomePathPosition(index + 1);
      case TrackPosition(:final index):
        if (index == approachIndex(color)) {
          return const HomePathPosition(0);
        }
        return TrackPosition((index + 1) % BoardConstants.trackLength);
    }
  }
}
