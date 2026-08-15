import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants.dart';

class DiceWidget extends StatefulWidget {
  const DiceWidget({
    super.key,
    required this.face,
    required this.enabled,
    required this.rolling,
    required this.onRoll,
  });

  final int face;
  final bool enabled;
  final bool rolling;
  final VoidCallback onRoll;

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  var _display = 1;

  static const _spinFaces = [1, 3, 5, 2, 6, 4, 3, 5, 1, 2];

  @override
  void initState() {
    super.initState();
    _display = widget.face;
    _controller = AnimationController(
      vsync: this,
      duration: TimingConstants.diceAnimation,
    )..addListener(() {
        final i = (_controller.value * _spinFaces.length).floor().clamp(
              0,
              _spinFaces.length - 1,
            );
        setState(() => _display = _spinFaces[i]);
      });
  }

  @override
  void didUpdateWidget(covariant DiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rolling && !oldWidget.rolling) {
      _controller.forward(from: 0).whenComplete(() {
        if (mounted) {
          setState(() => _display = widget.face);
        }
      });
    }
    if (!widget.rolling) {
      _display = widget.face;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bounce = Curves.elasticOut.transform(_controller.value.clamp(0, 1));
    return GestureDetector(
      onTap: widget.enabled && !widget.rolling ? widget.onRoll : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 92,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.goldRim, AppColors.goldDeep],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: widget.enabled ? 0.55 : 0.2),
                  blurRadius: 22,
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -18),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final tilt = math.sin(_controller.value * math.pi * 6) * 0.35;
                return Transform.rotate(
                  angle: tilt,
                  child: Transform.scale(
                    scale: widget.rolling ? 1 + 0.08 * bounce : 1,
                    child: child,
                  ),
                );
              },
              child: Opacity(
                opacity: widget.enabled || widget.rolling ? 1 : 0.55,
                child: _DiceFace(value: _display),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiceFace extends StatelessWidget {
  const _DiceFace({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF64B5F6), AppColors.diceBlue, AppColors.diceBlueDark],
        ),
        border: Border.all(color: Colors.white24, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x88000000), blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: CustomPaint(painter: _PipPainter(value.clamp(1, 6))),
    );
  }
}

class _PipPainter extends CustomPainter {
  _PipPainter(this.value);
  final int value;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    Offset p(double x, double y) => Offset(size.width * x, size.height * y);
    final r = size.width * 0.08;
    final spots = switch (value) {
      1 => [p(0.5, 0.5)],
      2 => [p(0.3, 0.3), p(0.7, 0.7)],
      3 => [p(0.3, 0.3), p(0.5, 0.5), p(0.7, 0.7)],
      4 => [p(0.3, 0.3), p(0.7, 0.3), p(0.3, 0.7), p(0.7, 0.7)],
      5 => [p(0.3, 0.3), p(0.7, 0.3), p(0.5, 0.5), p(0.3, 0.7), p(0.7, 0.7)],
      _ => [
          p(0.3, 0.28),
          p(0.7, 0.28),
          p(0.3, 0.5),
          p(0.7, 0.5),
          p(0.3, 0.72),
          p(0.7, 0.72),
        ],
    };
    for (final spot in spots) {
      canvas.drawCircle(spot, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PipPainter oldDelegate) =>
      oldDelegate.value != value;
}
