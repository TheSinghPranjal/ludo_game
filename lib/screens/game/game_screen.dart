import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../domain/models/game_status.dart';
import '../../domain/models/player_color.dart';
import '../../game/ludo_game.dart';
import '../../networking/protocol/messages.dart';
import '../../state/providers/session_provider.dart';
import '../widgets/debug_panel.dart';
import '../widgets/dice_widget.dart';
import '../widgets/game_background.dart';
import '../widgets/ludo_logo.dart';
import '../widgets/player_card.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late final LudoFlameGame _game;
  var _rolling = false;
  var _menuOpen = false;

  @override
  void initState() {
    super.initState();
    _game = LudoFlameGame(
      onTokenTapped: (id) => ref.read(sessionProvider.notifier).moveToken(id),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = ref.read(sessionProvider);
      if (session.game != null) {
        _game.syncState(session.game!, session.localPlayerId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final game = session.game;
    final turn = ref.watch(currentTurnProvider);

    ref.listen(sessionProvider, (prev, next) {
      final state = next.game;
      if (next.lastEvent != null && next.lastEvent != prev?.lastEvent) {
        _game.handleEvent(next.lastEvent!);
        if (next.lastEvent is DiceResultMessage) {
          setState(() => _rolling = true);
          Future<void>.delayed(TimingConstants.diceAnimation, () {
            if (mounted) {
              setState(() => _rolling = false);
            }
          });
        }
      }
      if (state != null) {
        _game.syncState(
          state,
          next.localPlayerId,
          snapIdle: next.lastEvent is CurrentGameStateMessage || prev == null,
        );
      }
      if (next.game?.status == GameStatus.finished &&
          prev?.game?.status != GameStatus.finished) {
        Navigator.pushNamed(context, '/result');
      }
      if (next.hostDisconnected) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Host disconnected'),
            content: const Text('The host left the game. Returning to the menu.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    });

    final players = {
      for (final color in PlayerColor.values)
        color: game?.players.where((p) => p.color == color).firstOrNull,
    };

    return GameBackground(
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const LudoLogo(size: 36),
                if (turn.label.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      turn.label,
                      style: TextStyle(
                        color: turn.isLocal
                            ? AppColors.gold
                            : AppColors.of(
                                game?.currentPlayer?.color ?? PlayerColor.green,
                              ),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (players[PlayerColor.green] != null)
                        PlayerHudCard(
                          player: players[PlayerColor.green]!,
                          isTurn: game?.currentPlayer?.color == PlayerColor.green,
                          isLocal: players[PlayerColor.green]!.playerId ==
                              session.localPlayerId,
                          compact: true,
                        )
                      else
                        const SizedBox(width: 8),
                      if (players[PlayerColor.yellow] != null)
                        PlayerHudCard(
                          player: players[PlayerColor.yellow]!,
                          isTurn: game?.currentPlayer?.color == PlayerColor.yellow,
                          isLocal: players[PlayerColor.yellow]!.playerId ==
                              session.localPlayerId,
                          compact: true,
                        )
                      else
                        const SizedBox(width: 8),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: GameWidget(game: _game),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (players[PlayerColor.red] != null)
                        PlayerHudCard(
                          player: players[PlayerColor.red]!,
                          isTurn: game?.currentPlayer?.color == PlayerColor.red,
                          isLocal: players[PlayerColor.red]!.playerId ==
                              session.localPlayerId,
                          compact: true,
                        )
                      else
                        const SizedBox(width: 8),
                      if (players[PlayerColor.blue] != null)
                        PlayerHudCard(
                          player: players[PlayerColor.blue]!,
                          isTurn: game?.currentPlayer?.color == PlayerColor.blue,
                          isLocal: players[PlayerColor.blue]!.playerId ==
                              session.localPlayerId,
                          compact: true,
                        )
                      else
                        const SizedBox(width: 8),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const SizedBox(width: 12),
                    Expanded(
                      child: GoldButton(
                        label: 'Leave Game',
                        icon: Icons.arrow_back,
                        onPressed: () async {
                          await ref.read(sessionProvider.notifier).leave();
                          if (context.mounted) {
                            Navigator.popUntil(context, (r) => r.isFirst);
                          }
                        },
                      ),
                    ),
                    DiceWidget(
                      face: game?.diceValue ?? 1,
                      enabled: ref.watch(diceProvider).enabled,
                      rolling: _rolling,
                      onRoll: () =>
                          ref.read(sessionProvider.notifier).rollDice(),
                    ),
                    Expanded(
                      child: GoldButton(
                        label: 'Menu',
                        icon: Icons.menu,
                        onPressed: () => setState(() => _menuOpen = !_menuOpen),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
            const DebugPanel(),
            if (_menuOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _menuOpen = false),
                  child: Container(
                    color: const Color(0x66000000),
                    alignment: Alignment.center,
                    child: GoldButton(
                      expanded: false,
                      label: 'Resume',
                      onPressed: () => setState(() => _menuOpen = false),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
