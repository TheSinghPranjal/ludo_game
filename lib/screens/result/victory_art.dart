import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../widgets/ludo_logo.dart';

/// Gold ribbon reading "[name] Wins!", or "Game Over" without a winner.
class VictoryBanner extends StatelessWidget {
  const VictoryBanner({super.key, required this.name, this.height = 96});

  final String? name;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, box) => CustomPaint(
          painter: _RibbonPainter(),
          child: Align(
            // Middle of the arched band.
            alignment: const Alignment(0, -0.28),
            child: SizedBox(
              width: box.maxWidth * 0.66,
              height: height * 0.46,
              child: FittedBox(fit: BoxFit.scaleDown, child: _label()),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label() {
    const blue = Color(0xFF1E5BD8);
    const red = Color(0xFFD92B1F);
    final size = height * 0.42;
    TextStyle style(Paint? stroke, Color fill) => TextStyle(
      fontFamily: AppFonts.display,
      fontSize: size,
      height: 1,
      foreground: stroke,
      color: stroke == null ? fill : null,
    );
    List<InlineSpan> spans(Paint? stroke) => [
      if (name != null) ...[
        TextSpan(text: '$name ', style: style(stroke, blue)),
        TextSpan(text: 'Wins!', style: style(stroke, red)),
      ] else
        TextSpan(text: 'Game Over', style: style(stroke, blue)),
    ];
    Paint outline(double width, Color color) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = width
      ..color = color;

    // Back to front: dark outline, white outline, coloured face.
    return Stack(
      children: [
        Transform.translate(
          offset: Offset(0, size * 0.06),
          child: Text.rich(
            TextSpan(
              children: spans(outline(size * 0.3, const Color(0xFF7A3E00))),
            ),
            maxLines: 1,
          ),
        ),
        Text.rich(
          TextSpan(children: spans(outline(size * 0.2, Colors.white))),
          maxLines: 1,
        ),
        Text.rich(TextSpan(children: spans(null)), maxLines: 1),
      ],
    );
  }
}

class _RibbonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    Offset p(double x, double y) => Offset(w * x, h * y);
    Path poly(List<Offset> points) => Path()..addPolygon(points, true);

    // Notched tails behind the band.
    for (final flip in [false, true]) {
      Offset q(double x, double y) => flip ? p(1 - x, y) : p(x, y);
      final tail = poly([
        q(0.01, 0.46),
        q(0.2, 0.46),
        q(0.2, 0.94),
        q(0.01, 0.94),
        q(0.08, 0.7),
      ]);
      canvas.drawPath(
        tail,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFCF4A), Color(0xFFE89400)],
          ).createShader(Offset.zero & size),
      );
      canvas.drawPath(
        tail,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = h * 0.025
          ..color = const Color(0xFFC77800),
      );
      canvas.drawPath(
        poly([q(0.12, 0.8), q(0.2, 0.8), q(0.2, 0.94)]),
        Paint()..color = const Color(0xFFA85A00),
      );
    }

    final band = Path()
      ..moveTo(w * 0.12, h * 0.3)
      ..quadraticBezierTo(w * 0.5, -h * 0.08, w * 0.88, h * 0.3)
      ..lineTo(w * 0.88, h * 0.8)
      ..quadraticBezierTo(w * 0.5, h * 0.42, w * 0.12, h * 0.8)
      ..close();
    canvas.drawPath(
      band.shift(Offset(0, h * 0.06)),
      Paint()..color = const Color(0x55000000),
    );
    canvas.drawPath(
      band,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFEA8A), Color(0xFFFFC21A), Color(0xFFF0A000)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      band,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = h * 0.03
        ..color = const Color(0xFFC77800),
    );
    // Glossy line along the top edge.
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.15, h * 0.35)
        ..quadraticBezierTo(w * 0.5, -h * 0.01, w * 0.85, h * 0.35),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = h * 0.025
        ..color = const Color(0x99FFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Trophy on a blue pedestal with rotating light rays and twinkles.
/// [loop] runs 0→1 repeatedly; [pop] is the entry scale of the trophy.
class TrophyScene extends StatelessWidget {
  const TrophyScene({super.key, required this.loop, required this.pop});

  final double loop;
  final double pop;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.infinite, painter: _TrophyPainter(loop, pop));
  }
}

class _TrophyPainter extends CustomPainter {
  _TrophyPainter(this.t, this.pop);

  final double t;
  final double pop;

  static const _rays = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final u = math.min(h * 0.94, w * 0.68);
    final top = (h - u) / 2;
    final c = w / 2;
    double y(double v) => top + v * u;

    // Light rays: rotate exactly one ray-gap per loop so the cycle is seamless.
    final focus = Offset(c, y(0.32));
    final reach = math.max(w, h) * 0.75;
    final rayPaint = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0x66FFF3B0), Color(0x00FFF3B0)],
      ).createShader(Rect.fromCircle(center: focus, radius: reach));
    final gap = math.pi * 2 / _rays;
    for (var i = 0; i < _rays; i++) {
      final a = i * gap + t * gap;
      canvas.drawPath(
        Path()
          ..moveTo(focus.dx, focus.dy)
          ..lineTo(
            focus.dx + math.cos(a - gap * 0.22) * reach,
            focus.dy + math.sin(a - gap * 0.22) * reach,
          )
          ..lineTo(
            focus.dx + math.cos(a + gap * 0.22) * reach,
            focus.dy + math.sin(a + gap * 0.22) * reach,
          )
          ..close(),
        rayPaint,
      );
    }
    canvas.drawCircle(
      focus,
      u * 0.55,
      Paint()
        ..shader = RadialGradient(
          colors: const [
            Color(0xAAFFF3B0),
            Color(0x55FFD54F),
            Color(0x00FFD54F),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(Rect.fromCircle(center: focus, radius: u * 0.55)),
    );

    for (final (i, (x, v, r)) in const [
      (-0.42, 0.18, 0.05),
      (0.44, 0.12, 0.04),
      (-0.36, 0.55, 0.045),
      (0.4, 0.5, 0.055),
      (-0.2, 0.02, 0.03),
      (0.24, 0.66, 0.03),
    ].indexed) {
      final twinkle = 0.6 + 0.4 * math.sin(math.pi * 2 * (t * 2 + i * 0.37));
      paintSparkle(
        canvas,
        Offset(c + x * u, y(v)),
        r * u * twinkle,
        i.isEven ? const Color(0xFFFFD54F) : const Color(0xFFFFF7D6),
      );
    }

    _drum(canvas, Offset(c, y(0.87)), u * 0.42, u * 0.08, u * 0.06);
    _drum(canvas, Offset(c, y(0.8)), u * 0.28, u * 0.055, u * 0.05);

    canvas.save();
    canvas.translate(c, y(0.8));
    canvas.scale(pop);
    canvas.translate(-c, -y(0.8));
    _trophy(canvas, c, u, y);
    canvas.restore();
  }

  void _drum(Canvas canvas, Offset top, double rx, double ry, double depth) {
    final topOval = Rect.fromCenter(center: top, width: rx * 2, height: ry * 2);
    final bottomOval = topOval.shift(Offset(0, depth));
    canvas.drawOval(
      bottomOval.shift(Offset(0, depth * 0.5)).inflate(rx * 0.04),
      Paint()
        ..color = const Color(0x55000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, ry * 0.4),
    );
    final side = Paint()..color = const Color(0xFF0D3A9C);
    canvas.drawOval(bottomOval, side);
    canvas.drawRect(
      Rect.fromLTRB(topOval.left, top.dy, topOval.right, top.dy + depth),
      side,
    );
    canvas.drawOval(
      bottomOval.deflate(rx * 0.01),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = rx * 0.025
        ..color = const Color(0xFFFFC21A),
    );
    canvas.drawOval(
      topOval,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5AA2FF), Color(0xFF1F57C4)],
        ).createShader(topOval),
    );
    canvas.drawOval(
      topOval,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = rx * 0.035
        ..color = const Color(0xFFFFD54F),
    );
  }

  void _trophy(Canvas canvas, double c, double u, double Function(double) y) {
    const deep = Color(0xFFC77800);
    final bounds = Rect.fromLTRB(c - u * 0.45, y(0), c + u * 0.45, y(0.8));
    final gold = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFE08A00),
          Color(0xFFFFE680),
          Color(0xFFFFC21A),
          Color(0xFFD98A00),
        ],
        stops: [0, 0.32, 0.66, 1],
      ).createShader(Rect.fromLTRB(c - u * 0.26, y(0), c + u * 0.26, y(1)));
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = u * 0.012
      ..color = deep;

    // Handles.
    for (final s in [-1.0, 1.0]) {
      final handle = Path()
        ..moveTo(c + s * u * 0.23, y(0.17))
        ..cubicTo(
          c + s * u * 0.43,
          y(0.11),
          c + s * u * 0.45,
          y(0.37),
          c + s * u * 0.14,
          y(0.43),
        );
      canvas.drawPath(
        handle,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = u * 0.06
          ..color = deep,
      );
      canvas.drawPath(
        handle,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = u * 0.035
          ..color = const Color(0xFFFFD54F),
      );
    }

    // Plinth, foot and stem.
    final plinth = RRect.fromRectAndRadius(
      Rect.fromLTRB(c - u * 0.17, y(0.68), c + u * 0.17, y(0.8)),
      Radius.circular(u * 0.025),
    );
    canvas.drawRRect(plinth, gold);
    canvas.drawRRect(plinth, edge);
    canvas.drawLine(
      Offset(c - u * 0.14, y(0.7)),
      Offset(c + u * 0.14, y(0.7)),
      Paint()
        ..strokeWidth = u * 0.01
        ..color = const Color(0x99FFFFFF),
    );
    final foot = Path()
      ..addPolygon([
        Offset(c - u * 0.05, y(0.59)),
        Offset(c + u * 0.05, y(0.59)),
        Offset(c + u * 0.13, y(0.68)),
        Offset(c - u * 0.13, y(0.68)),
      ], true);
    canvas.drawPath(foot, gold);
    canvas.drawPath(foot, edge);
    final stem = Rect.fromLTRB(c - u * 0.035, y(0.49), c + u * 0.035, y(0.6));
    canvas.drawRect(stem, gold);
    canvas.drawRect(stem, edge);
    final knob = Rect.fromCenter(
      center: Offset(c, y(0.54)),
      width: u * 0.13,
      height: u * 0.045,
    );
    canvas.drawOval(knob, gold);
    canvas.drawOval(knob, edge);

    // Bowl.
    final bowl = Path()
      ..moveTo(c - u * 0.25, y(0.11))
      ..cubicTo(
        c - u * 0.25,
        y(0.38),
        c - u * 0.12,
        y(0.48),
        c - u * 0.05,
        y(0.5),
      )
      ..lineTo(c + u * 0.05, y(0.5))
      ..cubicTo(
        c + u * 0.12,
        y(0.48),
        c + u * 0.25,
        y(0.38),
        c + u * 0.25,
        y(0.11),
      )
      ..close();
    canvas.drawPath(bowl, gold);
    canvas.drawPath(bowl, edge);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c - u * 0.14, y(0.25)),
        width: u * 0.05,
        height: u * 0.18,
      ),
      Paint()..color = const Color(0x77FFFFFF),
    );

    // Rim.
    final rim = Rect.fromCenter(
      center: Offset(c, y(0.11)),
      width: u * 0.54,
      height: u * 0.09,
    );
    canvas.drawOval(
      rim,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF0A0), Color(0xFFFFC21A)],
        ).createShader(rim),
    );
    canvas.drawOval(rim, edge);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c, y(0.113)),
        width: u * 0.44,
        height: u * 0.05,
      ),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB86A00), Color(0xFFE89A00)],
        ).createShader(bounds),
    );

    final star = _starPath(Offset(c, y(0.27)), u * 0.09, u * 0.042);
    canvas.drawPath(
      star,
      Paint()
        ..shader =
            const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF7C0), Color(0xFFFFC21A)],
            ).createShader(
              Rect.fromCircle(center: Offset(c, y(0.27)), radius: u * 0.09),
            ),
    );
    canvas.drawPath(star, edge);
  }

  @override
  bool shouldRepaint(covariant _TrophyPainter old) =>
      old.t != t || old.pop != pop;
}

Path _starPath(Offset c, double outer, double inner) {
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final r = i.isEven ? outer : inner;
    final a = -math.pi / 2 + i * math.pi / 5;
    final p = c + Offset(math.cos(a) * r, math.sin(a) * r);
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  return path..close();
}

/// Confetti strips and sparkles drifting in the top half of the screen.
class ConfettiPainter extends CustomPainter {
  ConfettiPainter(this.t);

  final double t;

  static const _colors = [
    Color(0xFFFFD54F),
    Color(0xFF4FA3FF),
    Color(0xFFF2463A),
    Color(0xFF3CCB5A),
    Color(0xFFE05BD0),
    Color(0xFF8C6CFF),
  ];

  // (x, y, angle, colour, length) — x/y as fractions of the screen.
  static const _pieces = [
    (0.2, 0.22, 0.6, 0, 0.07),
    (0.1, 0.38, -0.4, 0, 0.05),
    (0.22, 0.36, 0.9, 1, 0.06),
    (0.14, 0.44, -0.6, 3, 0.07),
    (0.06, 0.25, 0.3, 2, 0.04),
    (0.78, 0.37, -0.5, 2, 0.06),
    (0.82, 0.41, 0.4, 1, 0.055),
    (0.86, 0.46, 0.8, 4, 0.06),
    (0.92, 0.3, -0.3, 0, 0.04),
    (0.72, 0.18, 0.5, 3, 0.04),
    (0.3, 0.12, -0.8, 4, 0.035),
    (0.66, 0.1, 0.2, 1, 0.035),
  ];

  static const _sparkles = [
    (0.12, 0.23, 0.022, 0),
    (0.88, 0.24, 0.02, 1),
    (0.8, 0.2, 0.03, 0),
    (0.06, 0.48, 0.02, 5),
    (0.9, 0.38, 0.026, 3),
    (0.28, 0.05, 0.015, 1),
    (0.7, 0.06, 0.018, 0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    for (final (i, (x, y, angle, color, len)) in _pieces.indexed) {
      final phase = math.pi * 2 * t + i * 1.3;
      canvas.save();
      canvas.translate(w * x, h * y + math.sin(phase) * h * 0.008);
      canvas.rotate(angle + math.sin(phase) * 0.35);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: w * len,
        height: w * len * 0.38,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(w * 0.008)),
        Paint()..color = _colors[color],
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect
              .deflate(rect.height * 0.25)
              .shift(Offset(0, -rect.height * 0.12)),
          Radius.circular(w * 0.005),
        ),
        Paint()..color = const Color(0x55FFFFFF),
      );
      canvas.restore();
    }
    for (final (i, (x, y, r, color)) in _sparkles.indexed) {
      final twinkle = 0.55 + 0.45 * math.sin(math.pi * 2 * (t * 3 + i * 0.29));
      paintSparkle(
        canvas,
        Offset(w * x, h * y),
        w * r * twinkle,
        _colors[color],
      );
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter old) => old.t != t;
}

/// Rosette with ribbon tails showing a finishing place ("1st", "2nd"…).
class MedalBadge extends StatelessWidget {
  const MedalBadge({super.key, required this.place, this.size = 46});

  final int place;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$place${ordinalSuffix(place)} place',
      child: CustomPaint(
        size: Size.square(size),
        painter: _MedalPainter(place),
      ),
    );
  }
}

class _MedalPainter extends CustomPainter {
  _MedalPainter(this.place);

  final int place;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = size.center(Offset.zero);
    final (light, base, deep, ink, ribbon, ribbonDeep) = switch (place) {
      1 => (
        const Color(0xFFFFF0A0),
        const Color(0xFFFFC21A),
        const Color(0xFFE08A00),
        const Color(0xFF8A4B00),
        const Color(0xFFE53935),
        const Color(0xFFB71C14),
      ),
      2 => (
        const Color(0xFFFFFFFF),
        const Color(0xFFCFD8E3),
        const Color(0xFF8E9CB0),
        const Color(0xFF3E4A60),
        const Color(0xFF2F7BF0),
        const Color(0xFF1349B8),
      ),
      3 => (
        const Color(0xFFFFD8B4),
        const Color(0xFFE0915A),
        const Color(0xFFB0602A),
        const Color(0xFF5A2A0A),
        const Color(0xFF2DB845),
        const Color(0xFF178A30),
      ),
      _ => (
        const Color(0xFF8FB0F0),
        const Color(0xFF4A6FC0),
        const Color(0xFF243F8A),
        Colors.white,
        const Color(0xFF6A7C9E),
        const Color(0xFF465674),
      ),
    };

    // Ribbon tails hang below the rosette.
    for (final f in [-1.0, 1.0]) {
      Offset p(double x, double y) => c + Offset(f * x * s, y * s);
      final tail = Path()
        ..addPolygon([
          p(0.02, 0.12),
          p(0.2, 0.12),
          p(0.28, 0.62),
          p(0.18, 0.54),
          p(0.1, 0.64),
        ], true);
      canvas.drawPath(tail, Paint()..color = ribbon);
      canvas.drawPath(
        tail,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = s * 0.03
          ..color = ribbonDeep,
      );
    }

    // Scalloped rim.
    canvas.drawCircle(
      c.translate(0, s * 0.04),
      s * 0.46,
      Paint()
        ..color = const Color(0x55000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.04),
    );
    final rim = Paint()..color = deep;
    canvas.drawCircle(c, s * 0.4, rim);
    for (var i = 0; i < 14; i++) {
      final a = i * math.pi * 2 / 14;
      canvas.drawCircle(
        c + Offset(math.cos(a), math.sin(a)) * s * 0.4,
        s * 0.075,
        rim,
      );
    }
    final face = Rect.fromCircle(center: c, radius: s * 0.37);
    canvas.drawCircle(
      c,
      s * 0.37,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [light, base, deep],
          stops: const [0, 0.55, 1],
        ).createShader(face),
    );
    canvas.drawCircle(
      c,
      s * 0.3,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.025
        ..color = light.withValues(alpha: 0.8),
    );

    final text = TextPainter(
      text: TextSpan(
        style: TextStyle(fontFamily: AppFonts.display, color: ink, height: 1),
        children: [
          TextSpan(
            text: '$place',
            style: TextStyle(fontSize: s * 0.36),
          ),
          TextSpan(
            text: ordinalSuffix(place),
            style: TextStyle(fontSize: s * 0.2),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, c - Offset(text.width / 2, text.height / 2));
  }

  @override
  bool shouldRepaint(covariant _MedalPainter old) => old.place != place;
}

String ordinalSuffix(int n) => switch (n % 100) {
  11 || 12 || 13 => 'th',
  _ => switch (n % 10) {
    1 => 'st',
    2 => 'nd',
    3 => 'rd',
    _ => 'th',
  },
};
