import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants.dart';
import '../home/home_screen.dart';
import '../widgets/game_background.dart';
import '../widgets/ludo_logo.dart';

/// Short branded splash: the app name, then the Lazy Bear Club byline.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.hold = TimingConstants.splashHold});

  /// How long the splash stays visible before fading to the home screen.
  final Duration hold;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  Timer? _timer;
  var _showHome = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: TimingConstants.splashEntrance,
    )..forward();
    _timer = Timer(widget.hold, () {
      if (mounted) setState(() => _showHome = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: TimingConstants.splashFade,
      child: _showHome
          ? const HomeScreen(key: ValueKey('home'))
          : AnnotatedRegion<SystemUiOverlayStyle>(
              key: const ValueKey('splash'),
              value: SystemUiOverlayStyle.light,
              child: RepaintBoundary(
                key: const Key('splash-screen'),
                child: GameBackground(
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _entrance,
                      curve: Curves.easeOut,
                    ),
                    child: const SafeArea(child: _SplashBody()),
                  ),
                ),
              ),
            ),
    );
  }
}

class _SplashBody extends StatelessWidget {
  const _SplashBody();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shortest = math.min(constraints.maxWidth, constraints.maxHeight);
        final logoSize = (shortest * 0.2).clamp(56.0, 108.0);
        final titleSize = (shortest * 0.12).clamp(40.0, 68.0);
        const chrome = 20.0;
        final innerHeight = math.max(0.0, constraints.maxHeight - chrome);
        final bylineSlot = math.min(innerHeight * 0.42, 210.0);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LudoLogo(size: logoSize),
                        SizedBox(height: logoSize * 0.16),
                        Text(
                          'Ludo Game',
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppFonts.display,
                            fontSize: titleSize,
                            height: 1.05,
                            color: AppColors.gold,
                            shadows: const [
                              Shadow(
                                color: Color(0xFF0E1A66),
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: bylineSlot,
                width: double.infinity,
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomCenter,
                  child: _StudioByline(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// "by" on its own line, then the studio icon beside the studio name.
class _StudioByline extends StatelessWidget {
  const _StudioByline();

  @override
  Widget build(BuildContext context) {
    // The splash sits on the navy game background in both brightness modes,
    // so the credit uses light colors that stay readable there.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.navyPanel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x66FFD54F)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 18, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'by',
              style: AppFonts.uiStyle(
                size: 15,
                weight: 700,
                color: AppColors.goldRim,
                height: 1,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _BearMark(size: 64),
                const SizedBox(width: 12),
                Text(
                  'The Lazy Bear Club',
                  style: AppFonts.uiStyle(
                    size: 20,
                    weight: 800,
                    color: AppColors.textPrimary,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BearMark extends StatelessWidget {
  const _BearMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.22);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          'assets/branding/lazy_bear_club.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
