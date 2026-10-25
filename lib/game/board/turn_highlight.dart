import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../domain/models/player_color.dart';
import 'board_renderer.dart';

/// Blinks the yard of whoever's turn it is. Sits above the board and below
/// the tokens; only the coloured frame flashes so yard tokens stay clear.
class TurnHighlightComponent extends PositionComponent {
  TurnHighlightComponent()
    : super(size: Vector2.all(15), position: Vector2.zero());

  static const _periodSeconds = 1.0;

  PlayerColor? _color;
  var _phase = 0.0;

  PlayerColor? get color => _color;

  set color(PlayerColor? value) {
    if (value != _color) {
      _color = value;
      // Start each turn on a bright flash.
      _phase = math.pi / 2;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _phase += dt * math.pi * 2 / _periodSeconds;
  }

  @override
  void render(Canvas canvas) {
    final color = _color;
    if (color == null) {
      return;
    }
    // 0 → 1 → 0 once per period.
    final blink = 0.5 + 0.5 * math.sin(_phase);
    const cell = 1.0;
    final yard = BoardRenderer.yardShape(color, cell);
    final frame = Path()
      ..fillType = PathFillType.evenOdd
      ..addRRect(yard)
      ..addRRect(BoardRenderer.yardInset(color, cell));

    canvas.drawPath(
      frame,
      Paint()..color = Colors.white.withValues(alpha: 0.38 * blink),
    );
    canvas.drawRRect(
      yard.inflate(0.04),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.32
        ..color = const Color(0xFFFFE03A).withValues(alpha: 0.55 * blink)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.18),
    );
    canvas.drawRRect(
      yard.deflate(0.05),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.12
        ..color = const Color(
          0xFFFFF3A0,
        ).withValues(alpha: 0.35 + 0.65 * blink),
    );
  }
}
