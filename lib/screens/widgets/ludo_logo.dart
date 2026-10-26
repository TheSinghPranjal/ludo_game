import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants.dart';

/// Illustrated wordmark: crown, two dice and extruded "Ludo" lettering.
/// [size] is the letter height scale; the logo is about 3.1×1.6 of it.
class LudoLogo extends StatelessWidget {
  const LudoLogo({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 3.1,
      height: size * 1.62,
      child: CustomPaint(painter: _LogoPainter(size)),
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter(this.s);

  final double s;

  @override
  void paint(Canvas canvas, Size size) {
    _die(canvas, Offset(s * 0.9, s * 0.6), s * 0.6, -0.32, const [
      Color(0xFF6FB6FF),
      Color(0xFF2F7BF0),
      Color(0xFF1349B8),
    ], 5);
    _die(canvas, Offset(s * 2.2, s * 0.62), s * 0.54, 0.3, const [
      Color(0xFFFF7A6E),
      Color(0xFFF0372C),
      Color(0xFFB71C14),
    ], 3);
    _crown(canvas, Rect.fromLTWH(s * 1.13, 0, s * 0.84, s * 0.62));
    _word(canvas, size);

    for (final (x, y, r) in const [
      (0.22, 0.62, 0.13),
      (0.12, 1.14, 0.1),
      (2.78, 0.62, 0.13),
      (3.0, 1.12, 0.1),
      (0.5, 0.3, 0.06),
      (2.12, 0.28, 0.06),
    ]) {
      _sparkle(canvas, Offset(s * x, s * y), s * r);
    }
  }

  void _word(Canvas canvas, Size size) {
    final fontSize = s * 1.08;
    TextPainter layout(Paint paint) => TextPainter(
      text: TextSpan(
        text: 'Ludo',
        style: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: fontSize,
          height: 1,
          letterSpacing: s * 0.02,
          foreground: paint,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final probe = layout(Paint());
    final origin = Offset(
      s * 1.56 - probe.width / 2,
      s * 1.5 - probe.height * 0.9,
    );
    final bounds = origin & probe.size;
    canvas.save();
    canvas.translate(s * 1.56, 0);
    canvas.scale(1.12, 1);
    canvas.translate(-s * 1.56, 0);

    // Back to front: deep outline, outline, orange extrusion, gradient face.
    layout(
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = s * 0.26
        ..color = const Color(0xFF0E1A66),
    ).paint(canvas, origin.translate(0, s * 0.07));
    layout(
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = s * 0.2
        ..color = const Color(0xFF1F33A6),
    ).paint(canvas, origin);
    layout(
      Paint()..color = const Color(0xFFD45A00),
    ).paint(canvas, origin.translate(0, s * 0.06));
    layout(
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF7A8), Color(0xFFFFD43B), Color(0xFFFF9D00)],
          stops: [0.1, 0.5, 0.95],
        ).createShader(bounds),
    ).paint(canvas, origin);
    canvas.restore();
  }

  void _die(
    Canvas canvas,
    Offset center,
    double side,
    double angle,
    List<Color> colors,
    int pips,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: side,
      height: side,
    );
    final radius = Radius.circular(side * 0.24);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.shift(Offset(0, side * 0.1)), radius),
      Paint()..color = colors.last,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ).createShader(rect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(side * 0.04), radius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = side * 0.04
        ..color = const Color(0x55FFFFFF),
    );
    for (final p in _pipLayout(pips)) {
      canvas.drawCircle(
        Offset(p.dx * side, p.dy * side),
        side * 0.085,
        Paint()..color = Colors.white,
      );
    }
    canvas.restore();
  }

  void _crown(Canvas canvas, Rect r) {
    final w = r.width;
    final h = r.height;
    Offset p(double x, double y) => Offset(r.left + w * x, r.top + h * y);
    final body = Path()
      ..moveTo(p(0.08, 0.38).dx, p(0.08, 0.38).dy)
      ..lineTo(p(0.3, 0.6).dx, p(0.3, 0.6).dy)
      ..lineTo(p(0.5, 0.22).dx, p(0.5, 0.22).dy)
      ..lineTo(p(0.7, 0.6).dx, p(0.7, 0.6).dy)
      ..lineTo(p(0.92, 0.38).dx, p(0.92, 0.38).dy)
      ..lineTo(p(0.84, 0.86).dx, p(0.84, 0.86).dy)
      ..lineTo(p(0.16, 0.86).dx, p(0.16, 0.86).dy)
      ..close();
    final gold = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFEA7A), Color(0xFFFFC21A), Color(0xFFE08A00)],
      ).createShader(r);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = w * 0.035
      ..color = const Color(0xFFB86A00);

    canvas.drawPath(body, gold);
    canvas.drawPath(body, edge);
    final band = RRect.fromRectAndRadius(
      Rect.fromLTRB(p(0.14, 0).dx, p(0, 0.8).dy, p(0.86, 0).dx, p(0, 1).dy),
      Radius.circular(h * 0.06),
    );
    canvas.drawRRect(band, gold);
    canvas.drawRRect(band, edge);
    for (final (x, y) in const [(0.08, 0.34), (0.5, 0.16), (0.92, 0.34)]) {
      canvas.drawCircle(p(x, y), w * 0.065, gold);
      canvas.drawCircle(p(x, y), w * 0.065, edge);
    }
    canvas.drawCircle(
      p(0.5, 0.6),
      w * 0.07,
      Paint()..color = const Color(0xFFE53935),
    );
    canvas.drawCircle(
      p(0.48, 0.57),
      w * 0.025,
      Paint()..color = const Color(0x99FFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) => oldDelegate.s != s;
}

/// Pip centres for a die face, in -0.5..0.5 face coordinates.
List<Offset> _pipLayout(int value) {
  const a = 0.25;
  return switch (value) {
    1 => const [Offset.zero],
    2 => const [Offset(-a, -a), Offset(a, a)],
    3 => const [Offset(-a, -a), Offset.zero, Offset(a, a)],
    4 => const [Offset(-a, -a), Offset(a, -a), Offset(-a, a), Offset(a, a)],
    5 => const [
      Offset(-a, -a),
      Offset(a, -a),
      Offset.zero,
      Offset(-a, a),
      Offset(a, a),
    ],
    _ => const [
      Offset(-a, -a),
      Offset(a, -a),
      Offset(-a, 0),
      Offset(a, 0),
      Offset(-a, a),
      Offset(a, a),
    ],
  };
}

void _sparkle(
  Canvas canvas,
  Offset c,
  double r, [
  Color color = const Color(0xFFFFD54F),
]) {
  final path = Path()
    ..moveTo(c.dx, c.dy - r)
    ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
    ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
    ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
    ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
    ..close();
  canvas.drawPath(path, Paint()..color = color);
}

/// Chunky yellow button with a darker bottom lip.
class GoldButton extends StatelessWidget {
  const GoldButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
    this.chevron = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  /// Shows a ">" pinned to the right edge, with the label kept centred.
  final bool chevron;

  static const _radius = BorderRadius.all(Radius.circular(22));

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, color: AppColors.buttonText, size: 28),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: AppFonts.uiStyle(
                size: 22,
                weight: 900,
                color: AppColors.buttonText,
              ),
            ),
          ),
        ),
      ],
    );
    final child = DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFD98A00),
        borderRadius: _radius,
        boxShadow: [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: _radius,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFE45E), Color(0xFFFFCD1F), Color(0xFFFFB300)],
            ),
            border: Border.all(color: const Color(0xCCFFF2A6), width: 1.5),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: _radius,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: chevron
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: content,
                          ),
                          const Align(
                            alignment: Alignment.centerRight,
                            child: Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.buttonText,
                              size: 30,
                            ),
                          ),
                        ],
                      )
                    : content,
              ),
            ),
          ),
        ),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: child) : child;
  }
}

/// Blue bevelled icon button used in the game header.
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.circle = false,
    this.size = 40,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final bool circle;
  final double size;

  @override
  Widget build(BuildContext context) {
    final shape = circle
        ? const CircleBorder()
        : RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(size * 0.3),
          );
    return Tooltip(
      message: tooltip,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: shape,
          shadows: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          shape: shape.copyWith(
            side: const BorderSide(color: Color(0xFF4D93FF), width: 2.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1F57C4), Color(0xFF0D2E80)],
              ),
            ),
            child: InkWell(
              onTap: onPressed,
              child: Icon(icon, color: Colors.white, size: size * 0.58),
            ),
          ),
        ),
      ),
    );
  }
}

/// Die face used by the in-game dice: white cube, blue pips.
class DieFace extends StatelessWidget {
  const DieFace({super.key, required this.value, this.size = 58});

  final int value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _DieFacePainter(value.clamp(1, 6)),
    );
  }
}

class _DieFacePainter extends CustomPainter {
  _DieFacePainter(this.value);

  final int value;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.width;
    final radius = Radius.circular(side * 0.22);
    final body = Offset.zero & size;
    final face = Rect.fromLTWH(0, 0, side, side * 0.9);

    canvas.drawRRect(
      RRect.fromRectAndRadius(body.shift(Offset(0, side * 0.06)), radius),
      Paint()
        ..color = const Color(0x66000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, side * 0.06),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, radius),
      Paint()..color = const Color(0xFFB9C6DD),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(face, radius),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFEFF3FA), Color(0xFFDCE4F2)],
        ).createShader(face),
    );
    final c = face.center;
    for (final p in _pipLayout(value)) {
      final o = c + Offset(p.dx * side, p.dy * face.height);
      canvas.drawCircle(
        o.translate(0, side * 0.015),
        side * 0.085,
        Paint()..color = const Color(0xFF0E3C9C),
      );
      canvas.drawCircle(
        o,
        side * 0.08,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.4),
            colors: const [Color(0xFF4F8DFF), Color(0xFF1A52CC)],
          ).createShader(Rect.fromCircle(center: o, radius: side * 0.08)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DieFacePainter oldDelegate) =>
      oldDelegate.value != value;
}

/// Small gold crown marking whose turn it is.
class CrownBadge extends StatelessWidget {
  const CrownBadge({super.key, this.size = 30});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size * 0.74), painter: _CrownPainter());
  }
}

class _CrownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    _LogoPainter(0)._crown(canvas, Offset.zero & size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Crown flanked by a blue and a red die, used to crest dialogs.
/// The emblem is [height] tall and 2.4× as wide.
class DiceCrownEmblem extends StatelessWidget {
  const DiceCrownEmblem({super.key, this.height = 80});

  final double height;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(height * 2.4, height),
      painter: _EmblemPainter(),
    );
  }
}

class _EmblemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final u = size.height;
    final logo = _LogoPainter(0);
    logo._crown(canvas, Rect.fromLTWH(u * 0.78, 0, u * 0.84, u * 0.64));
    logo._die(canvas, Offset(u * 0.66, u * 0.56), u * 0.6, -0.26, const [
      Color(0xFF6FB6FF),
      Color(0xFF2F7BF0),
      Color(0xFF1349B8),
    ], 5);
    logo._die(canvas, Offset(u * 1.76, u * 0.56), u * 0.56, 0.28, const [
      Color(0xFFFF7A6E),
      Color(0xFFF0372C),
      Color(0xFFB71C14),
    ], 3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Faint 4-point sparkle, exposed for background art.
void paintSparkle(
  Canvas canvas,
  Offset c,
  double r, [
  Color color = const Color(0xFFFFD54F),
]) => _sparkle(canvas, c, r, color);

/// Tilt helper for decorative shapes.
double degrees(double d) => d * math.pi / 180;
