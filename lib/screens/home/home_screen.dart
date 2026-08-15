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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 36),
              const LudoLogo(size: 72),
              const Spacer(),
              GoldButton(
                label: 'LOCAL MULTIPLAYER',
                icon: Icons.wifi_tethering,
                onPressed: () => Navigator.pushNamed(context, '/local'),
              ),
              const SizedBox(height: 16),
              GoldButton(
                label: 'SETTINGS',
                icon: Icons.settings,
                onPressed: () => Navigator.pushNamed(context, '/settings'),
              ),
              const SizedBox(height: 48),
              Text(
                'Host-authoritative  ·  Wi-Fi / Hotspot',
                style: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.9)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
