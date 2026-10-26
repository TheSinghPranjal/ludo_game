import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../widgets/game_background.dart';
import '../widgets/ludo_logo.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GameBackground(
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 28),
            const LudoLogo(size: 80),
            // Board, pawns and dice, centred in whatever space is left.
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  child: Image.asset(
                    'assets/home/hero.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Column(
                children: [
                  GoldButton(
                    label: 'PLAY ON THIS DEVICE',
                    icon: Icons.smartphone,
                    chevron: true,
                    onPressed: () => Navigator.pushNamed(context, '/hotseat'),
                  ),
                  const SizedBox(height: 16),
                  GoldButton(
                    label: 'WI-FI MULTIPLAYER',
                    icon: Icons.wifi_tethering,
                    chevron: true,
                    onPressed: () => Navigator.pushNamed(context, '/local'),
                  ),
                  const SizedBox(height: 16),
                  GoldButton(
                    label: 'SETTINGS',
                    icon: Icons.settings,
                    chevron: true,
                    onPressed: () => Navigator.pushNamed(context, '/settings'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const _FeatureRow(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// "Same rules | Unbiased dice | No internet required" strip at the bottom.
class _FeatureRow extends StatelessWidget {
  const _FeatureRow();

  @override
  Widget build(BuildContext context) {
    Widget divider() =>
        Container(width: 1, height: 64, color: const Color(0x334F7FD8));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const _Feature(image: 'feature_players', label: 'Same rules'),
          divider(),
          const _Feature(image: 'feature_dice', label: 'Unbiased dice'),
          divider(),
          const _Feature(
            image: 'feature_offline',
            label: 'No internet required',
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.image, required this.label});

  final String image;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Image.asset('assets/home/$image.png', width: 48, height: 48),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: AppFonts.uiStyle(
                size: 12.5,
                weight: 600,
                color: AppColors.subtleText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
