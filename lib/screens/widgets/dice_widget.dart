import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants.dart';
import 'ludo_logo.dart';

class DiceWidget extends StatefulWidget {
  const DiceWidget({
    super.key,
    required this.face,
    required this.enabled,
    required this.rolling,
    required this.onRoll,
    this.secondsRemaining,
  });

  final int face;
  final bool enabled;
  final bool rolling;
  final VoidCallback onRoll;
  final int? secondsRemaining;

  static const size = Size(108, 118);

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
    _controller =
        AnimationController(
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
    final seconds = widget.secondsRemaining;
    final urgent =
        seconds != null && seconds <= TimingConstants.timerUrgencySeconds;
    final progress = seconds == null
        ? 1.0
        : (seconds / TimingConstants.turnTimerSeconds).clamp(0.0, 1.0);
    final live = widget.enabled || widget.rolling;

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: 'Roll dice',
      child: GestureDetector(
        onTap: widget.enabled && !widget.rolling ? widget.onRoll : null,
        child: SizedBox.fromSize(
          size: DiceWidget.size,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              const Positioned(
                bottom: 0,
                child: CustomPaint(
                  size: Size(82, 24),
                  painter: _PedestalPainter(),
                ),
              ),
              Positioned(
                top: 12,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(
                          alpha: widget.enabled ? 0.55 : 0.15,
                        ),
                        blurRadius: 18,
                      ),
                      const BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: _RingPainter(progress: progress, urgent: urgent),
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          final tilt =
                              math.sin(_controller.value * math.pi * 6) * 0.28;
                          final bounce = Curves.elasticOut.transform(
                            _controller.value.clamp(0, 1),
                          );
                          return Transform.rotate(
                            angle: tilt,
                            child: Transform.scale(
                              scale: widget.rolling ? 1 + 0.06 * bounce : 1,
                              child: child,
                            ),
                          );
                        },
                        child: Opacity(
                          opacity: live ? 1 : 0.7,
                          child: DieFace(value: _display, size: 56),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (seconds != null)
                Positioned(
                  top: 0,
                  child: Container(
                    width: 52,
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: urgent
                            ? const [Color(0xFFFF6B5E), AppColors.redDeep]
                            : const [Color(0xFFFFE36B), Color(0xFFFFB800)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: urgent
                            ? const Color(0xFF8E120C)
                            : const Color(0xFFD08A00),
                        width: 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x55000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${seconds}s',
                      style: AppFonts.uiStyle(
                        size: 14,
                        weight: 900,
                        color: urgent ? Colors.white : AppColors.buttonText,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gold bezel with a blue well. The bright arc shows the turn time left.
class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.urgent});

  final double progress;
  final bool urgent;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final outer = size.width / 2;
    const ring = 9.0;
    final rect = Rect.fromCircle(center: c, radius: outer);

    canvas.drawCircle(c, outer, Paint()..color = const Color(0xFF9A5E00));
    canvas.drawCircle(
      c,
      outer - ring / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring
        ..color = const Color(0xFFC88A1E),
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: outer - ring / 2),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring
        ..strokeCap = progress < 1 ? StrokeCap.round : StrokeCap.butt
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: urgent
              ? const [Color(0xFFFF8A80), AppColors.red]
              : const [Color(0xFFFFF0A0), Color(0xFFFFC21A), Color(0xFFF2A100)],
        ).createShader(rect),
    );
    final well = outer - ring;
    canvas.drawCircle(
      c,
      well,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.2),
          colors: [Color(0xFF56A4FF), Color(0xFF2266DD), Color(0xFF0D3A9E)],
          stops: [0, 0.6, 1],
        ).createShader(Rect.fromCircle(center: c, radius: well)),
    );
    canvas.drawCircle(
      c,
      well,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x66061A4A),
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.urgent != urgent;
}

/// Gold stand the dice bezel rests on.
class _PedestalPainter extends CustomPainter {
  const _PedestalPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final top = Path()
      ..moveTo(w * 0.2, 0)
      ..lineTo(w * 0.8, 0)
      ..lineTo(w, h * 0.62)
      ..lineTo(0, h * 0.62)
      ..close();
    final base = RRect.fromLTRBR(0, h * 0.5, w, h, Radius.circular(h * 0.3));
    canvas.drawRRect(base, Paint()..color = const Color(0xFFC07800));
    canvas.drawPath(
      top,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE27A), Color(0xFFF5A800)],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
