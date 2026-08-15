import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../state/providers/session_provider.dart';
import '../widgets/game_background.dart';
import '../widgets/ludo_logo.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final game = session.game;
    final winner = game?.players
        .where((p) => p.playerId == game.winnerId)
        .firstOrNull;

    return GameBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              const LudoLogo(size: 48),
              const SizedBox(height: 24),
              Text(
                winner == null ? 'Game over' : '${winner.name} wins!',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              if (game != null)
                ...game.players.map((player) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.of(player.color),
                    ),
                    title: Text(
                      player.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: Text(
                      player.playerId == game.winnerId ? '1st' : player.color.displayName,
                      style: const TextStyle(color: AppColors.gold),
                    ),
                  );
                }),
              const Spacer(),
              GoldButton(
                label: 'Play Again',
                onPressed: () {
                  if (session.isHost) {
                    ref.read(sessionProvider.notifier).playAgain();
                    Navigator.popUntil(
                      context,
                      (r) => r.settings.name == '/host' || r.isFirst,
                    );
                    if (ModalRoute.of(context)?.settings.name != '/host') {
                      Navigator.pushNamed(context, '/host');
                    }
                  } else {
                    Navigator.popUntil(
                      context,
                      (r) => r.settings.name == '/join' || r.isFirst,
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              GoldButton(
                label: 'Exit',
                onPressed: () async {
                  await ref.read(sessionProvider.notifier).leave();
                  if (context.mounted) {
                    Navigator.popUntil(context, (r) => r.isFirst);
                  }
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
