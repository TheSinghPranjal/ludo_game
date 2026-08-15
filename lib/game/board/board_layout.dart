import 'package:flame/components.dart';

import '../../domain/models/board_position.dart';
import '../../domain/models/player_color.dart';
import '../../domain/rules/board_map.dart';

abstract final class BoardLayout {
  static Vector2 toWorld(PlayerColor color, BoardPosition position) {
    final (col, row) = BoardMap.cellOf(color, position);
    return Vector2(col + 0.5, row + 0.5);
  }
}
