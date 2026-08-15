import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../domain/models/player_color.dart';
import '../../domain/rules/board_map.dart';

/// Paints the 15×15 Ludo board. Layout matches the reference image.
abstract final class BoardRenderer {
  static void paint(Canvas canvas, Size size) {
    final cell = size.width / BoardConstants.gridSize;
    _drawFrame(canvas, size, cell);
    _drawYards(canvas, cell);
    _drawPath(canvas, cell);
    _drawCenter(canvas, cell);
    _drawStarsAndArrows(canvas, cell);
    canvas.restore();
  }

  static void _drawFrame(Canvas canvas, Size size, double cell) {
    final board = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(board, Radius.circular(cell * 0.35));

    canvas.drawRRect(
      rrect.shift(Offset(0, cell * 0.06)),
      Paint()..color = const Color(0x66000000),
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          colors: [AppColors.goldRim, AppColors.gold, AppColors.goldDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(board),
    );

    final inner = rrect.deflate(cell * 0.16);
    canvas.drawRRect(inner, Paint()..color = const Color(0xFF2B2118));
    canvas.save();
    canvas.clipRRect(inner);
  }

  static void _drawYards(Canvas canvas, double cell) {
    for (final color in PlayerColor.values) {
      final origin = BoardConstants.yardOrigin[color]!;
      final rect = Rect.fromLTWH(
        origin.$1 * cell,
        origin.$2 * cell,
        6 * cell,
        6 * cell,
      );
      final outer = RRect.fromRectAndRadius(
        rect.deflate(cell * 0.08),
        Radius.circular(cell * 0.42),
      );
      canvas.drawRRect(
        outer.shift(Offset(0, cell * 0.05)),
        Paint()..color = const Color(0x33000000),
      );
      canvas.drawRRect(
        outer,
        Paint()
          ..shader = LinearGradient(
            colors: [AppColors.of(color), AppColors.deepOf(color)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(rect),
      );
      canvas.drawRRect(
        outer,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * 0.045
          ..color = const Color(0x88FFD54F),
      );

      final inset = RRect.fromRectAndRadius(
        rect.deflate(cell * 0.72),
        Radius.circular(cell * 0.32),
      );
      canvas.drawRRect(inset, Paint()..color = AppColors.boardWhite);
      canvas.drawRRect(
        inset,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * 0.04
          ..color = const Color(0x33000000),
      );

      for (final slot in BoardConstants.baseSlots[color]!) {
        final c = Offset((slot.$1 + 0.5) * cell, (slot.$2 + 0.5) * cell);
        canvas.drawCircle(
          c.translate(0, cell * 0.04),
          cell * 0.52,
          Paint()..color = const Color(0x22000000),
        );
        canvas.drawCircle(
          c,
          cell * 0.5,
          Paint()..color = AppColors.of(color).withValues(alpha: 0.22),
        );
        canvas.drawCircle(
          c,
          cell * 0.5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * 0.055
            ..color = AppColors.of(color),
        );
        canvas.drawCircle(
          c.translate(-cell * 0.12, -cell * 0.14),
          cell * 0.12,
          Paint()..color = const Color(0x55FFFFFF),
        );
      }
    }
  }

  static void _drawPath(Canvas canvas, double cell) {
    for (var row = 0; row < BoardConstants.gridSize; row++) {
      for (var col = 0; col < BoardConstants.gridSize; col++) {
        if (!_isPathCell(col, row)) {
          continue;
        }
        final rect = Rect.fromLTWH(col * cell, row * cell, cell, cell);
        final fill = _cellColor(col, row);
        final rrect = RRect.fromRectAndRadius(
          rect.deflate(cell * 0.045),
          Radius.circular(cell * 0.12),
        );
        canvas.drawRRect(rrect, Paint()..color = fill);
        canvas.drawRRect(
          rrect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * 0.055
            ..color = AppColors.cellBorder,
        );
        canvas.drawLine(
          Offset(rrect.left + cell * 0.08, rrect.top + cell * 0.08),
          Offset(rrect.right - cell * 0.1, rrect.top + cell * 0.08),
          Paint()
            ..color = AppColors.cellInnerHighlight
            ..strokeWidth = cell * 0.03,
        );
      }
    }
  }

  static void _drawCenter(Canvas canvas, double cell) {
    final rect = Rect.fromLTWH(6 * cell, 6 * cell, 3 * cell, 3 * cell);
    final center = rect.center;
    final corners = [
      rect.topLeft,
      rect.topRight,
      rect.bottomRight,
      rect.bottomLeft,
    ];
    final colors = [
      AppColors.yellow,
      AppColors.blue,
      AppColors.red,
      AppColors.green,
    ];
    for (var i = 0; i < 4; i++) {
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(corners[i].dx, corners[i].dy)
        ..lineTo(corners[(i + 1) % 4].dx, corners[(i + 1) % 4].dy)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            colors: [colors[i], colors[i].withValues(alpha: 0.85)],
          ).createShader(rect),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * 0.04
          ..color = AppColors.cellBorder,
      );
    }
  }

  static void _drawStarsAndArrows(Canvas canvas, double cell) {
    for (final index in BoardConstants.starTrackIndices) {
      final (col, row) = BoardConstants.trackCells[index];
      _star(
        canvas,
        Offset((col + 0.5) * cell, (row + 0.5) * cell),
        cell * 0.32,
      );
    }

    const arrows = <PlayerColor, (int, int, double)>{
      PlayerColor.green: (1, 8, 0),
      PlayerColor.red: (8, 13, -math.pi / 2),
      PlayerColor.blue: (13, 6, math.pi),
      PlayerColor.yellow: (6, 1, math.pi / 2),
    };
    for (final entry in arrows.entries) {
      final (col, row, angle) = entry.value;
      _arrow(
        canvas,
        Offset((col + 0.5) * cell, (row + 0.5) * cell),
        cell * 0.28,
        angle,
      );
    }
  }

  static void _star(Canvas canvas, Offset c, double r) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? r : r * 0.42;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final p = Offset(
        c.dx + radius * math.cos(angle),
        c.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFC107));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.08
        ..color = const Color(0xFFF57F17),
    );
  }

  static void _arrow(Canvas canvas, Offset c, double r, double angle) {
    final path = Path()
      ..moveTo(r, 0)
      ..lineTo(-r * 0.55, r * 0.7)
      ..lineTo(-r * 0.2, 0)
      ..lineTo(-r * 0.55, -r * 0.7)
      ..close();
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.08
        ..color = const Color(0x33000000),
    );
    canvas.restore();
  }

  static bool _isPathCell(int col, int row) {
    final inCross = (row >= 6 && row <= 8) || (col >= 6 && col <= 8);
    final inCenter = row >= 6 && row <= 8 && col >= 6 && col <= 8;
    return inCross && !inCenter;
  }

  static Color _cellColor(int col, int row) {
    for (final color in PlayerColor.values) {
      final start = BoardConstants.trackCells[BoardMap.startIndex(color)];
      if (start.$1 == col && start.$2 == row) {
        return AppColors.of(color);
      }
      for (final cell in BoardConstants.homePathCells[color]!) {
        if (cell.$1 == col && cell.$2 == row) {
          return AppColors.of(color);
        }
      }
    }
    final even = (col + row).isEven;
    return even ? AppColors.boardWhite : AppColors.boardWhiteAlt;
  }
}
