import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../domain/models/board_position.dart';
import '../../domain/models/player_color.dart';
import '../../domain/rules/board_map.dart';
import 'marble_painter.dart';

class TokenComponent extends PositionComponent with TapCallbacks {
  TokenComponent({
    required this.tokenId,
    required this.color,
    required this.slot,
    required this.onTapped,
    super.position,
  }) : super(anchor: Anchor.center, size: Vector2.all(0.92));

  final String tokenId;
  final PlayerColor color;
  final int slot;
  final void Function(String tokenId) onTapped;

  var highlighted = false;
  var invalidShake = 0.0;
  var _pulse = 0.0;
  var animating = false;
  BoardPosition? logical;

  /// Draw offset that fans out tokens sharing a square; zero when alone.
  /// [fan] eases towards [fanTarget] so tokens slide apart and back.
  final fan = Vector2.zero();
  Vector2 fanTarget = Vector2.zero();

  void snapTo(BoardPosition position) {
    logical = position;
    _fitTo(position);
    this.position = worldOf(color, position, slot: slot);
  }

  static const _boardSize = 0.92;
  static const _yardSize = 1.4;

  /// Resting in the yard the marble is drawn large, like the yard art.
  void _fitTo(BoardPosition position) {
    size = Vector2.all(position is BasePosition ? _yardSize : _boardSize);
  }

  static Vector2 worldOf(
    PlayerColor color,
    BoardPosition position, {
    int slot = 0,
  }) {
    if (position is BasePosition) {
      final (ox, oy) = BoardConstants.yardOrigin[color]!;
      final (dx, dy) = BoardConstants.baseSlotOffsets[position.slot];
      return Vector2(ox + dx, oy + dy);
    }
    final (col, row) = BoardMap.cellOf(color, position);
    return Vector2(col + 0.5, row + 0.5);
  }

  Future<void> travel(List<BoardPosition> path) async {
    if (path.isEmpty) {
      return;
    }
    animating = true;
    fanTarget = Vector2.zero();
    _fitTo(path.first);
    for (final step in path) {
      final dest = worldOf(color, step, slot: slot);
      final from = position.clone();
      final ms = TimingConstants.tokenStep.inMilliseconds;
      final frames = math.max(1, (ms / 16).round());
      for (var i = 1; i <= frames; i++) {
        final t = i / frames;
        final eased = Curves.easeInOut.transform(t);
        position = from + (dest - from) * eased;
        await Future<void>.delayed(const Duration(milliseconds: 16));
      }
      position = dest;
      scale = Vector2.all(1.12);
      await Future<void>.delayed(TimingConstants.tokenBounce);
      scale = Vector2.all(1);
      logical = step;
    }
    animating = false;
  }

  Future<void> flyTo(BoardPosition destPos) async {
    animating = true;
    fanTarget = Vector2.zero();
    final dest = worldOf(color, destPos, slot: slot);
    final from = position.clone();
    final ms = TimingConstants.captureFlight.inMilliseconds;
    final frames = math.max(1, (ms / 16).round());
    for (var i = 1; i <= frames; i++) {
      final t = Curves.easeInOut.transform(i / frames);
      final arc = math.sin(t * math.pi) * 0.9;
      position = from + (dest - from) * t + Vector2(0, -arc);
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
    position = dest;
    logical = destPos;
    _fitTo(destPos);
    animating = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (highlighted) {
      _pulse += dt * (math.pi * 2 / TimingConstants.highlightPulseSeconds);
    }
    fan.add((fanTarget - fan)..scale(math.min(1, dt * 12)));
    if (invalidShake > 0) {
      invalidShake = math.max(0, invalidShake - dt * 8);
    }
  }

  @override
  void render(Canvas canvas) {
    final shake = math.sin(invalidShake * 40) * 0.04 * invalidShake;
    canvas.save();
    canvas.translate(fan.x, fan.y);
    canvas.save();
    canvas.translate(shake * size.x, 0);

    final rect = Offset.zero & Size(size.x, size.y);
    final c = rect.center;
    final r = size.x * 0.44;

    if (highlighted) {
      _drawHalo(canvas, c, r);
    }

    MarblePainter.paint(canvas, c, r, color);
    canvas.restore();

    if (highlighted) {
      _drawPointer(canvas, c, r);
    }
    canvas.restore();
  }

  static const _haloNavy = Color(0xFF0E2A80);
  static const _haloYellow = Color(0xFFFFE03A);

  /// Bright yellow ring with a navy edge so it reads on any square or
  /// token colour, plus a pulsing outer glow.
  void _drawHalo(Canvas canvas, Offset c, double r) {
    final glow = 0.5 + 0.5 * math.sin(_pulse);
    final ringR = r * (1.13 + 0.04 * glow);

    canvas.drawCircle(
      c,
      ringR + r * 0.28,
      Paint()
        ..color = _haloYellow.withValues(alpha: 0.45 + 0.35 * glow)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.32),
    );
    canvas.drawCircle(
      c,
      ringR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.3
        ..color = _haloNavy.withValues(alpha: 0.85),
    );
    canvas.drawCircle(
      c,
      ringR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.2
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF7B0), _haloYellow, Color(0xFFFFB300)],
        ).createShader(Rect.fromCircle(center: c, radius: ringR)),
    );
    canvas.drawCircle(
      c,
      ringR - r * 0.1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.04
        ..color = Colors.white.withValues(alpha: 0.6 + 0.4 * glow),
    );
  }

  /// Bobbing gold arrow above the token, pointing down at it.
  void _drawPointer(Canvas canvas, Offset c, double r) {
    final bob = math.sin(_pulse) * r * 0.16;
    final tipY = c.dy - r * 1.42 - bob;
    final w = r * 0.5;
    final h = r * 0.62;
    final path = Path()
      ..moveTo(c.dx, tipY)
      ..lineTo(c.dx - w, tipY - h)
      ..lineTo(c.dx + w, tipY - h)
      ..close();
    final bounds = Rect.fromLTRB(c.dx - w, tipY - h, c.dx + w, tipY);

    canvas.drawPath(
      path.shift(Offset(0, r * 0.08)),
      Paint()..color = const Color(0x55000000),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = r * 0.2
        ..color = _haloNavy,
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF3A0), _haloYellow, Color(0xFFF59E00)],
        ).createShader(bounds),
    );
    canvas.drawLine(
      Offset(c.dx - w * 0.55, tipY - h * 0.8),
      Offset(c.dx + w * 0.55, tipY - h * 0.8),
      Paint()
        ..strokeWidth = r * 0.06
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xAAFFFFFF),
    );
  }

  @override
  void onTapUp(TapUpEvent event) {
    onTapped(tokenId);
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    return (point - fan - size / 2).length <= size.x * 0.45;
  }

  void shake() {
    invalidShake = 1;
  }
}
