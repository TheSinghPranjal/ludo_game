import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../domain/models/game_status.dart';
import '../../domain/models/player_color.dart';
import '../../state/providers/session_provider.dart';
import '../widgets/game_background.dart';
import '../widgets/ludo_logo.dart';
import '../widgets/player_card.dart';

class JoinGameScreen extends ConsumerStatefulWidget {
  const JoinGameScreen({super.key});

  @override
  ConsumerState<JoinGameScreen> createState() => _JoinGameScreenState();
}

class _JoinGameScreenState extends ConsumerState<JoinGameScreen> {
  final _ip = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _ip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final game = session.game;

    ref.listen(sessionProvider, (prev, next) {
      if (next.game?.status == GameStatus.active &&
          prev?.game?.status != GameStatus.active) {
        Navigator.pushNamed(context, '/game');
      }
      if (next.hostDisconnected) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Host disconnected')));
        Navigator.popUntil(context, (route) => route.isFirst);
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
                'Enter the host IP shown on the host device.\nExample: 192.168.43.1',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ip,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '192.168.x.x',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GoldButton(
                label: _busy ? 'CONNECTING…' : 'CONNECT',
                onPressed: _busy
                    ? null
                    : () async {
                        setState(() => _busy = true);
                        try {
                          await ref
                              .read(sessionProvider.notifier)
                              .joinGame(_ip.text);
                        } catch (_) {
                        } finally {
                          if (mounted) {
                            setState(() => _busy = false);
                          }
                        }
                      },
              ),
              if (session.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    session.error!,
                    style: const TextStyle(color: AppColors.red),
                  ),
                ),
              const SizedBox(height: 12),
              if (game != null)
                Expanded(
                  child: ListView(
                    children: [
                      for (final color in PlayerColor.values)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: LobbyPlayerTile(
                            color: color,
                            player: game.players
                                .where((p) => p.color == color)
                                .firstOrNull,
                            selected:
                                game
                                    .playerById(session.localPlayerId ?? '')
                                    ?.color ==
                                color,
                            onTap: () => ref
                                .read(sessionProvider.notifier)
                                .claimColor(color),
                          ),
                        ),
                      GoldButton(
                        label:
                            (game
                                    .playerById(session.localPlayerId ?? '')
                                    ?.isReady ??
                                false)
                            ? 'UNREADY'
                            : 'READY',
                        onPressed: () {
                          final ready =
                              game
                                  .playerById(session.localPlayerId ?? '')
                                  ?.isReady ??
                              false;
                          ref.read(sessionProvider.notifier).ready(!ready);
                        },
                      ),
                    ],
                  ),
                )
              else
                const Spacer(),
              TextButton(
                onPressed: () async {
                  await ref.read(sessionProvider.notifier).leave();
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text(
                  'Back',
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
