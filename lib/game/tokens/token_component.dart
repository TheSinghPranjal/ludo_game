import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../domain/models/board_position.dart';
import '../../domain/models/player_color.dart';
import '../../domain/rules/board_map.dart';

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

  void snapTo(BoardPosition position) {
    logical = position;
    this.position = worldOf(color, position, slot: slot);
  }

  static Vector2 worldOf(PlayerColor color, BoardPosition position, {int slot = 0}) {
    final (col, row) = BoardMap.cellOf(color, position);
    final ox = position is BasePosition || position is HomePosition
        ? 0.0
        : (slot.isEven ? -0.1 : 0.1);
    final oy = position is BasePosition || position is HomePosition
        ? 0.0
        : (slot < 2 ? -0.1 : 0.1);
    return Vector2(col + 0.5 + ox, row + 0.5 + oy);
  }

  Future<void> travel(List<BoardPosition> path) async {
    if (path.isEmpty) {
      return;
    }
    animating = true;
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
    animating = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (highlighted) {
      _pulse += dt * (math.pi * 2 / TimingConstants.highlightPulseSeconds);
    }
    if (invalidShake > 0) {
      invalidShake = math.max(0, invalidShake - dt * 8);
    }
  }

  @override
  void render(Canvas canvas) {
    final shake = math.sin(invalidShake * 40) * 0.04 * invalidShake;
    canvas.save();
    canvas.translate(shake * size.x, 0);

    final rect = Offset.zero & Size(size.x, size.y);
    final c = rect.center;
    final r = size.x * 0.38;

    if (highlighted) {
      final glow = 0.55 + 0.45 * math.sin(_pulse);
      canvas.drawCircle(
        c,
        r * (1.45 + 0.12 * math.sin(_pulse)),
        Paint()
          ..color = AppColors.gold.withValues(alpha: 0.22 + 0.2 * glow)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
        c,
        r * 1.28,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.05
          ..color = Colors.white.withValues(alpha: 0.7 + 0.3 * glow),
      );
    }

    canvas.drawOval(
      Rect.fromCenter(
        center: c.translate(0, r * 0.55),
        width: r * 1.35,
        height: r * 0.42,
      ),
      Paint()..color = const Color(0x66000000),
    );

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.lerp(AppColors.of(color), Colors.white, 0.25)!,
            AppColors.of(color),
            AppColors.deepOf(color),
          ],
          stops: const [0.15, 0.55, 1],
          center: const Alignment(-0.35, -0.4),
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.035
        ..color = const Color(0xAA000000),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: c.translate(-r * 0.28, -r * 0.32),
        width: r * 0.42,
        height: r * 0.28,
      ),
      Paint()..color = const Color(0xCCFFFFFF),
    );
    canvas.restore();

    if (highlighted) {
      _drawPointer(canvas, c, r);
    }
  }

  void _drawPointer(Canvas canvas, Offset c, double r) {
    final bob = math.sin(_pulse) * 0.08;
    final path = Path()
      ..moveTo(c.dx, c.dy - r * 1.85 + bob)
      ..lineTo(c.dx - r * 0.32, c.dy - r * 1.35 + bob)
      ..lineTo(c.dx + r * 0.32, c.dy - r * 1.35 + bob)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.gold);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.03
        ..color = AppColors.goldDeep,
    );
  }

  @override
  void onTapUp(TapUpEvent event) {
    onTapped(tokenId);
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    return (point - size / 2).length <= size.x * 0.45;
  }

  void shake() {
    invalidShake = 1;
  }
}
