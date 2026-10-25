import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../state/providers/session_provider.dart';
import '../widgets/game_background.dart';
import '../widgets/ludo_logo.dart';

class LocalMultiplayerScreen extends ConsumerWidget {
  const LocalMultiplayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GameBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const LudoLogo(size: 48),
              const SizedBox(height: 12),
              const Text(
                'Host a game on this Wi-Fi or hotspot.\nFriends join from their own phones.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
              const Spacer(),
              GoldButton(
                label: 'CREATE GAME',
                icon: Icons.add_circle_outline,
                onPressed: () async {
                  await ref.read(sessionProvider.notifier).hostGame();
                  if (context.mounted) {
                    Navigator.pushNamed(context, '/host');
                  }
                },
              ),
              const SizedBox(height: 16),
              GoldButton(
                label: 'JOIN GAME',
                icon: Icons.login,
                onPressed: () => Navigator.pushNamed(context, '/join'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Back',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
