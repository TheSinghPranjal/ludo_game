import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../domain/models/game_status.dart';
import '../../domain/models/player_color.dart';
import '../../state/providers/session_provider.dart';
import '../widgets/game_background.dart';
import '../widgets/ludo_logo.dart';
import '../widgets/player_card.dart';

class HostLobbyScreen extends ConsumerWidget {
  const HostLobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final game = session.game;

    ref.listen(sessionProvider, (prev, next) {
      if (next.game?.status == GameStatus.active &&
          prev?.game?.status != GameStatus.active) {
        Navigator.pushNamed(context, '/game');
      }
    });

    return GameBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const LudoLogo(size: 40),
              const SizedBox(height: 8),
              const Text(
                'You are the host. Enable a hotspot or stay on Wi-Fi, then share your IP.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'HOST ADDRESS',
                      style: TextStyle(color: AppColors.gold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      session.connectedHost ?? 'Starting…',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (session.hostIps.length > 1)
                      Text(
                        session.hostIps.join('  ·  '),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    TextButton.icon(
                      onPressed: session.connectedHost == null
                          ? null
                          : () {
                              Clipboard.setData(
                                ClipboardData(text: session.connectedHost!),
                              );
                            },
                      icon: const Icon(
                        Icons.copy,
                        color: AppColors.gold,
                        size: 16,
                      ),
                      label: const Text(
                        'Copy',
                        style: TextStyle(color: AppColors.gold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Android hotspot IP is often 192.168.43.1\n'
                'iPhone hotspot IP is often 172.20.10.1',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    for (final color in PlayerColor.values)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: LobbyPlayerTile(
                          color: color,
                          player: game?.players
                              .where((p) => p.color == color)
                              .firstOrNull,
                          selected:
                              game
                                  ?.playerById(session.localPlayerId ?? '')
                                  ?.color ==
                              color,
                          onTap: () => ref
                              .read(sessionProvider.notifier)
                              .claimColor(color),
                        ),
                      ),
                  ],
                ),
              ),
              SwitchListTile(
                value: game?.aiEnabled ?? false,
                onChanged: (v) =>
                    ref.read(sessionProvider.notifier).setAiEnabled(v),
                title: const Text(
                  'Fill empty slots with AI',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Off by default. Does not add AI to a normal match.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: GoldButton(
                      label:
                          (game
                                  ?.playerById(session.localPlayerId ?? '')
                                  ?.isReady ??
                              false)
                          ? 'UNREADY'
                          : 'READY',
                      onPressed: () {
                        final ready =
                            game
                                ?.playerById(session.localPlayerId ?? '')
                                ?.isReady ??
                            false;
                        ref.read(sessionProvider.notifier).ready(!ready);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GoldButton(
                      label: 'START',
                      onPressed: () =>
                          ref.read(sessionProvider.notifier).startGame(),
                    ),
                  ),
                ],
              ),
              if (session.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    session.error!,
                    style: const TextStyle(color: AppColors.red),
                  ),
                ),
              TextButton(
                onPressed: () async {
                  await ref.read(sessionProvider.notifier).leave();
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text(
                  'Leave',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
