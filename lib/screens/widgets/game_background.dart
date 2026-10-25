import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'ludo_logo.dart';

class GameBackground extends StatelessWidget {
  const GameBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.15),
          radius: 1.1,
          colors: [Color(0xFF1D52B8), Color(0xFF133E94), Color(0xFF0A2566)],
          stops: [0, 0.55, 1],
        ),
      ),
      child: CustomPaint(
        painter: const _BackdropPainter(),
        child: Scaffold(backgroundColor: Colors.transparent, body: child),
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter();

  static const _faint = Color(0x1A9CC4FF);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Large soft discs in the corners.
    canvas.drawCircle(
      Offset(-w * 0.05, h * 0.05),
      w * 0.36,
      Paint()..color = const Color(0x14FFFFFF),
    );
    canvas.drawCircle(
      Offset(w * 1.02, h * 0.12),
      w * 0.42,
      Paint()..color = const Color(0x22061A4A),
    );
    canvas.drawCircle(
      Offset(-w * 0.04, h * 1.0),
      w * 0.26,
      Paint()..color = const Color(0x33061A4A),
    );
    canvas.drawCircle(
      Offset(w * 1.03, h * 1.0),
      w * 0.26,
      Paint()..color = const Color(0x33061A4A),
    );

    // Faint decorations: a crown, a die and a few stars.
    _crown(canvas, Rect.fromLTWH(w * 0.05, h * 0.115, w * 0.12, w * 0.09));
    _die(canvas, Offset(w * 0.9, h * 0.21), w * 0.1, 0.5);
    for (final (x, y, r) in const [
      (0.75, 0.22, 0.035),
      (0.96, 0.11, 0.03),
      (0.45, 0.8, 0.03),
      (0.28, 0.78, 0.02),
    ]) {
      _star(canvas, Offset(w * x, h * y), w * r);
    }
    paintSparkle(canvas, Offset(w * 0.3, h * 0.055), w * 0.012);

    // Leaves peeking in from the bottom corners.
    _leaf(canvas, Offset(-w * 0.02, h * 0.79), w * 0.2, degrees(-30));
    _leaf(canvas, Offset(-w * 0.03, h * 0.84), w * 0.17, degrees(-5));
    _leaf(canvas, Offset(w * 0.0, h * 0.73), w * 0.13, degrees(-60));
    _leaf(canvas, Offset(w * 1.02, h * 0.85), w * 0.17, degrees(200));
    _leaf(canvas, Offset(w * 1.03, h * 0.8), w * 0.13, degrees(235));
  }

  void _crown(Canvas canvas, Rect r) {
    final path = Path()
      ..moveTo(r.left, r.top + r.height * 0.25)
      ..lineTo(r.left + r.width * 0.3, r.top + r.height * 0.55)
      ..lineTo(r.left + r.width * 0.5, r.top)
      ..lineTo(r.left + r.width * 0.7, r.top + r.height * 0.55)
      ..lineTo(r.right, r.top + r.height * 0.25)
      ..lineTo(r.right - r.width * 0.1, r.bottom)
      ..lineTo(r.left + r.width * 0.1, r.bottom)
      ..close();
    canvas.save();
    canvas.translate(r.center.dx, r.center.dy);
    canvas.rotate(degrees(-12));
    canvas.translate(-r.center.dx, -r.center.dy);
    canvas.drawPath(path, Paint()..color = _faint);
    canvas.restore();
  }

  void _die(Canvas canvas, Offset c, double side, double angle) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: side,
      height: side,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(side * 0.22)),
      Paint()..color = _faint,
    );
    final pip = Paint()..color = const Color(0x22061A4A);
    for (final (x, y) in const [
      (-0.25, -0.25),
      (0.25, -0.25),
      (0.0, 0.0),
      (-0.25, 0.25),
      (0.25, 0.25),
    ]) {
      canvas.drawCircle(Offset(x * side, y * side), side * 0.08, pip);
    }
    canvas.restore();
  }

  void _star(Canvas canvas, Offset c, double r) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? r : r * 0.5;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final p = c + Offset(math.cos(angle), math.sin(angle)) * radius;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path..close(), Paint()..color = _faint);
  }

  /// Leaf whose stem sits at [stem], extending [length] along [angle].
  void _leaf(Canvas canvas, Offset stem, double length, double angle) {
    canvas.save();
    canvas.translate(stem.dx, stem.dy);
    canvas.rotate(angle);
    final half = length * 0.32;
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(length * 0.45, -half, length, 0)
      ..quadraticBezierTo(length * 0.45, half, 0, 0)
      ..close();
    final bounds = Rect.fromLTWH(0, -half, length, half * 2);
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4CC266), Color(0xFF1F7A3A)],
        ).createShader(bounds),
    );
    canvas.drawLine(
      Offset(length * 0.05, 0),
      Offset(length * 0.85, 0),
      Paint()
        ..color = const Color(0x6694E8A4)
        ..strokeWidth = length * 0.025
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
