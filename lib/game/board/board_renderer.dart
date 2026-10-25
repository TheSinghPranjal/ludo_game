import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../domain/models/player_color.dart';
import '../../domain/rules/board_map.dart';
import '../tokens/marble_painter.dart';

/// Paints the 15×15 Ludo board plus its wooden frame, which extends outside
/// the grid by the BoardConstants.frame* margins.
abstract final class BoardRenderer {
  static const _seam = Color(0xFFDCD5CA);
  static const _tile = Color(0xFFFFFFFF);
  static const _tileShade = Color(0xFFF1EEE8);

  /// [idleColors] are yards without a player; they show resting marbles.
  static void paint(
    Canvas canvas,
    Size size, {
    Set<PlayerColor> idleColors = const {},
  }) {
    final cell = size.width / BoardConstants.gridSize;
    _drawFrame(canvas, size, cell);
    _drawYards(canvas, cell, idleColors);
    _drawPath(canvas, cell);
    _drawCenter(canvas, cell);
    _drawStarsAndArrows(canvas, cell);
  }

  static void _drawFrame(Canvas canvas, Size size, double cell) {
    final outer = Rect.fromLTRB(
      -BoardConstants.frameSide * cell,
      -BoardConstants.frameTop * cell,
      size.width + BoardConstants.frameSide * cell,
      size.height + BoardConstants.frameBottom * cell,
    );
    final radius = Radius.circular(cell * 0.5);
    final lip = RRect.fromRectAndRadius(outer, radius);
    final face = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        outer.left,
        outer.top,
        outer.right,
        outer.bottom - cell * 0.2,
      ),
      radius,
    );

    // Drop shadow and the darker bottom lip that gives the frame depth.
    canvas.drawRRect(
      lip.shift(Offset(0, cell * 0.18)),
      Paint()
        ..color = const Color(0x55000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.25),
    );
    canvas.drawRRect(lip, Paint()..color = const Color(0xFFAE5F16));
    canvas.drawRRect(
      face,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF4B05A), Color(0xFFE8963A), Color(0xFFD9822A)],
        ).createShader(outer),
    );
    canvas.drawRRect(
      face.deflate(cell * 0.05),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.05
        ..color = const Color(0x66FFF1D6),
    );

    // Light play surface; the gaps between tiles read as seams.
    final grid = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height).inflate(cell * 0.04),
      Radius.circular(cell * 0.22),
    );
    canvas.drawRRect(grid, Paint()..color = _seam);
    canvas.drawRRect(
      grid,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.05
        ..color = const Color(0x55A0652A),
    );
  }

  /// Outer coloured block of a yard.
  static RRect yardShape(PlayerColor color, double cell) {
    final origin = BoardConstants.yardOrigin[color]!;
    final rect = Rect.fromLTWH(
      origin.$1 * cell,
      origin.$2 * cell,
      6 * cell,
      6 * cell,
    ).deflate(cell * 0.06);
    return RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.4));
  }

  /// White inset panel inside a yard that holds the resting tokens.
  static RRect yardInset(PlayerColor color, double cell) {
    final rect = yardShape(color, cell).outerRect;
    return RRect.fromRectAndRadius(
      Rect.fromLTRB(
        rect.left + cell * 0.68,
        rect.top + cell * 0.68,
        rect.right - cell * 0.68,
        rect.bottom - cell * 0.74,
      ),
      Radius.circular(cell * 0.5),
    );
  }

  static void _drawYards(
    Canvas canvas,
    double cell,
    Set<PlayerColor> idleColors,
  ) {
    for (final color in PlayerColor.values) {
      final origin = BoardConstants.yardOrigin[color]!;
      final yard = yardShape(color, cell);
      final rect = yard.outerRect;
      final base = AppColors.of(color);
      final deep = AppColors.deepOf(color);

      // Bevelled colour block: darker band at the bottom for thickness.
      canvas.drawRRect(yard, Paint()..color = deep);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            rect.left,
            rect.top,
            rect.right,
            rect.bottom - cell * 0.14,
          ),
          Radius.circular(cell * 0.4),
        ),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(base, Colors.white, 0.12)!, base, deep],
            stops: const [0, 0.55, 1],
          ).createShader(rect),
      );

      final inset = yardInset(color, cell);
      final insetRect = inset.outerRect;
      canvas.drawRRect(
        inset.shift(Offset(0, cell * 0.08)),
        Paint()
          ..color = Color.lerp(
            deep,
            Colors.black,
            0.25,
          )!.withValues(alpha: 0.45),
      );
      canvas.drawRRect(
        inset,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFF3EFE8)],
          ).createShader(insetRect),
      );

      final idle = idleColors.contains(color);
      for (final (dx, dy) in BoardConstants.baseSlotOffsets) {
        final c = Offset((origin.$1 + dx) * cell, (origin.$2 + dy) * cell);
        if (idle) {
          MarblePainter.paint(canvas, c, cell * 0.62, color);
        } else {
          // Empty socket: visible only when its token has left the yard.
          canvas.drawCircle(
            c,
            cell * 0.56,
            Paint()..color = base.withValues(alpha: 0.16),
          );
          canvas.drawCircle(
            c,
            cell * 0.56,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = cell * 0.05
              ..color = base.withValues(alpha: 0.45),
          );
        }
      }
    }
  }

  static void _drawPath(Canvas canvas, double cell) {
    for (var row = 0; row < BoardConstants.gridSize; row++) {
      for (var col = 0; col < BoardConstants.gridSize; col++) {
        if (!_isPathCell(col, row)) {
          continue;
        }
        final rect = Rect.fromLTWH(
          col * cell,
          row * cell,
          cell,
          cell,
        ).deflate(cell * 0.045);
        final rrect = RRect.fromRectAndRadius(
          rect,
          Radius.circular(cell * 0.1),
        );
        final color = _cellColor(col, row);
        if (color == null) {
          canvas.drawRRect(
            rrect,
            Paint()
              ..shader = const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_tile, _tileShade],
              ).createShader(rect),
          );
        } else {
          canvas.drawRRect(
            rrect,
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(AppColors.of(color), Colors.white, 0.1)!,
                  Color.lerp(
                    AppColors.of(color),
                    AppColors.deepOf(color),
                    0.2,
                  )!,
                ],
              ).createShader(rect),
          );
        }
        canvas.drawLine(
          Offset(rect.left + cell * 0.1, rect.top + cell * 0.06),
          Offset(rect.right - cell * 0.1, rect.top + cell * 0.06),
          Paint()
            ..color = const Color(0x55FFFFFF)
            ..strokeWidth = cell * 0.04,
        );
      }
    }
  }

  static void _drawCenter(Canvas canvas, double cell) {
    final rect = Rect.fromLTWH(
      6 * cell,
      6 * cell,
      3 * cell,
      3 * cell,
    ).deflate(cell * 0.03);
    final center = rect.center;
    final corners = [
      rect.topLeft,
      rect.topRight,
      rect.bottomRight,
      rect.bottomLeft,
    ];
    const colors = [
      PlayerColor.yellow,
      PlayerColor.blue,
      PlayerColor.red,
      PlayerColor.green,
    ];
    for (var i = 0; i < 4; i++) {
      final a = corners[i];
      final b = corners[(i + 1) % 4];
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..close();
      final edgeMid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment(
              (edgeMid.dx - center.dx) / (rect.width / 2),
              (edgeMid.dy - center.dy) / (rect.height / 2),
            ),
            end: Alignment.center,
            colors: [
              Color.lerp(AppColors.of(colors[i]), Colors.white, 0.1)!,
              Color.lerp(
                AppColors.of(colors[i]),
                AppColors.deepOf(colors[i]),
                0.5,
              )!,
            ],
          ).createShader(rect),
      );
    }
  }

  static void _drawStarsAndArrows(Canvas canvas, double cell) {
    for (final index in BoardConstants.starTrackIndices) {
      final (col, row) = BoardConstants.trackCells[index];
      _star(
        canvas,
        Offset((col + 0.5) * cell, (row + 0.5) * cell),
        cell * 0.33,
      );
    }

    const arrows = <PlayerColor, double>{
      PlayerColor.green: 0,
      PlayerColor.yellow: math.pi / 2,
      PlayerColor.blue: math.pi,
      PlayerColor.red: -math.pi / 2,
    };
    for (final entry in arrows.entries) {
      final (col, row) =
          BoardConstants.trackCells[BoardMap.startIndex(entry.key)];
      _arrow(
        canvas,
        Offset((col + 0.5) * cell, (row + 0.5) * cell),
        cell * 0.32,
        entry.value,
      );
    }
  }

  static void _star(Canvas canvas, Offset c, double r) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? r : r * 0.48;
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
    canvas.drawPath(
      path.shift(Offset(0, r * 0.12)),
      Paint()..color = const Color(0x33000000),
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE066), Color(0xFFFFB300)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = r * 0.14
        ..color = const Color(0xFFE08A00),
    );
  }

  /// Block arrow with a shaft, pointing along +x before rotation.
  static void _arrow(Canvas canvas, Offset c, double r, double angle) {
    final path = Path()
      ..moveTo(r, 0)
      ..lineTo(r * 0.05, -r * 0.8)
      ..lineTo(r * 0.05, -r * 0.3)
      ..lineTo(-r * 0.9, -r * 0.3)
      ..lineTo(-r * 0.9, r * 0.3)
      ..lineTo(r * 0.05, r * 0.3)
      ..lineTo(r * 0.05, r * 0.8)
      ..close();
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    canvas.drawPath(
      path.shift(Offset(0, r * 0.1)),
      Paint()..color = const Color(0x40000000),
    );
    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.restore();
  }

  static bool _isPathCell(int col, int row) {
    final inCross = (row >= 6 && row <= 8) || (col >= 6 && col <= 8);
    final inCenter = row >= 6 && row <= 8 && col >= 6 && col <= 8;
    return inCross && !inCenter;
  }

  /// Player colour for start squares and home columns, otherwise null.
  static PlayerColor? _cellColor(int col, int row) {
    for (final color in PlayerColor.values) {
      final start = BoardConstants.trackCells[BoardMap.startIndex(color)];
      if (start.$1 == col && start.$2 == row) {
        return color;
      }
      for (final cell in BoardConstants.homePathCells[color]!) {
        if (cell.$1 == col && cell.$2 == row) {
          return color;
        }
      }
    }
    return null;
  }
}
