import '../../core/constants.dart';
import '../models/board_position.dart';
import '../models/player_color.dart';
import 'board_map.dart';

abstract final class TokenMovement {
  /// Destination after [dice] steps, or null if the move is illegal.
  static BoardPosition? destination({
    required PlayerColor color,
    required BoardPosition current,
    required int dice,
  }) {
    if (dice < 1 || dice > RuleConstants.diceFaces) {
      return null;
    }

    switch (current) {
      case HomePosition():
        return null;
      case BasePosition():
        if (dice != RuleConstants.leaveBaseRequires) {
          return null;
        }
        return TrackPosition(BoardMap.startIndex(color));
      case HomePathPosition(:final index):
        final landing = index + dice;
        if (landing == BoardConstants.homePathLength) {
          return const HomePosition();
        }
        if (landing > BoardConstants.homePathLength) {
          return null;
        }
        return HomePathPosition(landing);
      case TrackPosition(:final index):
        final approach = BoardMap.approachIndex(color);
        final toApproach =
            (approach - index + BoardConstants.trackLength) %
                BoardConstants.trackLength;
        if (dice <= toApproach) {
          return TrackPosition(
            (index + dice) % BoardConstants.trackLength,
          );
        }
        final intoHome = dice - toApproach;
        if (intoHome == 1 + BoardConstants.homePathLength) {
          return const HomePosition();
        }
        if (intoHome > 1 + BoardConstants.homePathLength) {
          return null;
        }
        return HomePathPosition(intoHome - 1);
    }
  }
}
