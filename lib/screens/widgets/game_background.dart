import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants.dart';

class GameBackground extends StatelessWidget {
  const GameBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.1),
          radius: 1.15,
          colors: [
            Color(0xFF16325C),
            AppColors.background,
            AppColors.backgroundDeep,
          ],
        ),
      ),
      child: CustomPaint(
        painter: const _BackdropPainter(),
        child: child,
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.gridLine.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    const step = 28.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final center = Offset(size.width / 2, size.height * 0.42);
    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + math.cos(angle - 0.08) * size.height,
          center.dy + math.sin(angle - 0.08) * size.height,
        )
        ..lineTo(
          center.dx + math.cos(angle + 0.08) * size.height,
          center.dy + math.sin(angle + 0.08) * size.height,
        )
        ..close();
      canvas.drawPath(
        path,
        Paint()..color = const Color(0x14FFE082),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
