import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../domain/models/player_color.dart';

/// Glossy marble on a darker ring, shared by live tokens and idle yards.
abstract final class MarblePainter {
  static void paint(
    Canvas canvas,
    Offset c,
    double r,
    PlayerColor color, {
    double opacity = 1,
  }) {
    final base = AppColors.of(color);
    final deep = AppColors.deepOf(color);
    final darker = Color.lerp(deep, Colors.black, 0.35)!;
    Color a(Color color) => color.withValues(alpha: color.a * opacity);

    // Contact shadow.
    canvas.drawOval(
      Rect.fromCenter(
        center: c.translate(0, r * 0.62),
        width: r * 1.9,
        height: r * 0.7,
      ),
      Paint()..color = a(const Color(0x40000000)),
    );

    // Ring: a shallow dish, darker at the top so the marble looks seated.
    final ringRect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [a(darker), a(deep), a(Color.lerp(base, Colors.white, 0.2)!)],
          stops: const [0, 0.55, 1],
        ).createShader(ringRect),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.07
        ..color = a(darker),
    );

    // Sphere.
    final sr = r * 0.76;
    final sphereCenter = c.translate(0, -r * 0.05);
    canvas.drawCircle(
      sphereCenter,
      sr,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 1,
          colors: [a(Color.lerp(base, Colors.white, 0.45)!), a(base), a(deep)],
          stops: const [0, 0.5, 1],
        ).createShader(Rect.fromCircle(center: sphereCenter, radius: sr)),
    );
    canvas.drawCircle(
      sphereCenter,
      sr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.04
        ..color = a(darker.withValues(alpha: 0.6)),
    );

    // Specular highlights.
    canvas.drawOval(
      Rect.fromCenter(
        center: sphereCenter.translate(-sr * 0.32, -sr * 0.42),
        width: sr * 0.62,
        height: sr * 0.38,
      ),
      Paint()..color = a(const Color(0xD9FFFFFF)),
    );
    canvas.drawCircle(
      sphereCenter.translate(sr * 0.38, sr * 0.36),
      sr * 0.09,
      Paint()..color = a(const Color(0x66FFFFFF)),
    );
  }
}
