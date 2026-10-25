import 'package:flutter/material.dart';

import '../../core/constants.dart';
import 'ludo_logo.dart';

enum GameDialogActionStyle { primary, secondary, danger }

class GameDialogAction<T> {
  const GameDialogAction({
    required this.label,
    required this.value,
    this.icon,
    this.style = GameDialogActionStyle.primary,
  });

  final String label;
  final T value;
  final IconData? icon;
  final GameDialogActionStyle style;
}

/// Themed confirmation popup: dice-and-crown crest, blue header band,
/// gold rim and chunky buttons. Resolves to the tapped action's value.
Future<T?> showGameDialog<T>({
  required BuildContext context,
  required String title,
  required String message,
  required List<GameDialogAction<T>> actions,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: const Color(0xAA020814),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, _, _) =>
        _GameDialog<T>(title: title, message: message, actions: actions),
    transitionBuilder: (ctx, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: ScaleTransition(
        scale: Tween(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeIn,
          ),
        ),
        child: child,
      ),
    ),
  );
}

class _GameDialog<T> extends StatelessWidget {
  const _GameDialog({
    required this.title,
    required this.message,
    required this.actions,
  });

  final String title;
  final String message;
  final List<GameDialogAction<T>> actions;

  static const _emblemHeight = 78.0;
  static const _bandHeight = 44.0;

  @override
  Widget build(BuildContext context) {
    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE27A), Color(0xFFFFB300), Color(0xFFE08A00)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
          BoxShadow(color: Color(0x44FFD54F), blurRadius: 24, spreadRadius: 2),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF6CB4FF), Color(0xFF2F7BF0)],
                stops: [0, 0.18],
              ),
            ),
            child: CustomPaint(
              painter: _BandSparklePainter(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, _bandHeight, 6, 6),
                child: _body(),
              ),
            ),
          ),
        ),
      ),
    );

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Material(
              type: MaterialType.transparency,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: _emblemHeight * 0.55),
                    child: card,
                  ),
                  const DiceCrownEmblem(height: _emblemHeight),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFDF8), Color(0xFFF7EEDC)],
        ),
        border: Border.all(color: const Color(0xFFFFF4D6), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 26, 18, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 32,
                height: 1.1,
                color: Color(0xFF0E2A80),
                shadows: [
                  Shadow(color: Color(0x33000000), offset: Offset(0, 2)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppFonts.uiStyle(
                size: 16,
                weight: 700,
                color: const Color(0xFF4A5670),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                for (final (i, action) in actions.indexed) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: _DialogButton<T>(action: action)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogButton<T> extends StatelessWidget {
  const _DialogButton({required this.action});

  final GameDialogAction<T> action;

  static const _radius = BorderRadius.all(Radius.circular(20));

  @override
  Widget build(BuildContext context) {
    final (faces, lip, rim, ink) = switch (action.style) {
      GameDialogActionStyle.primary => (
        const [Color(0xFF6CB4FF), Color(0xFF2F7BF0), Color(0xFF1F57C4)],
        const Color(0xFF0D2E80),
        const Color(0xAAB8DAFF),
        Colors.white,
      ),
      GameDialogActionStyle.secondary => (
        const [Color(0xFFFFFFFF), Color(0xFFEAF3FF), Color(0xFFD3E5FF)],
        const Color(0xFF9DBBEA),
        const Color(0xFFFFFFFF),
        const Color(0xFF1546B8),
      ),
      GameDialogActionStyle.danger => (
        const [Color(0xFFFF8A6B), Color(0xFFF54A33), Color(0xFFE0301F)],
        const Color(0xFFA8180F),
        const Color(0xAAFFC2B5),
        Colors.white,
      ),
    };

    return Semantics(
      button: true,
      label: action.label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: lip,
          borderRadius: _radius,
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: _radius,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: faces,
              ),
              border: Border.all(color: rim, width: 1.5),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: _radius,
                onTap: () => Navigator.pop(context, action.value),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 13,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (action.icon != null) ...[
                        Icon(action.icon, color: ink, size: 24),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            action.label,
                            maxLines: 1,
                            style: AppFonts.uiStyle(
                              size: 20,
                              weight: 900,
                              color: ink,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft sparkles either side of the crest, inside the blue band.
class _BandSparklePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const color = Color(0xCCE3F0FF);
    paintSparkle(canvas, Offset(size.width * 0.13, 24), 7, color);
    paintSparkle(canvas, Offset(size.width * 0.87, 22), 6, color);
    paintSparkle(canvas, Offset(size.width * 0.06, 12), 3.5, color);
    paintSparkle(canvas, Offset(size.width * 0.94, 34), 3.5, color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
