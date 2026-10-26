import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../domain/models/game_status.dart';
import '../../domain/models/player_color.dart';
import '../../domain/models/player_state.dart';
import '../../game/ludo_game.dart';
import '../../networking/protocol/messages.dart';
import '../../state/providers/session_provider.dart';
import '../../state/session_state.dart';
import '../widgets/dice_widget.dart';
import '../widgets/game_background.dart';
import '../widgets/game_dialog.dart';
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
  var _resultShown = false;
  String? _banner;
  String? _lastRollerId;
  var _bannerGen = 0;

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
  void dispose() {
    _game.busy.dispose();
    super.dispose();
  }

  void _showBanner(String text) {
    final gen = ++_bannerGen;
    setState(() => _banner = text);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted && gen == _bannerGen) {
        setState(() => _banner = null);
      }
    });
  }

  Future<void> _showResultWhenSettled() async {
    if (_resultShown) {
      return;
    }
    _resultShown = true;
    // Let the winning token finish its walk home first.
    await _game.settled;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted ||
        ref.read(sessionProvider).game?.status != GameStatus.finished) {
      _resultShown = false;
      return;
    }
    await Navigator.pushNamed(context, '/result');
    _resultShown = false;
  }

  Future<void> _confirmLeave() async {
    final leave = await showGameDialog<bool>(
      context: context,
      title: 'Leave Game?',
      message: 'The current game will end.',
      actions: const [
        GameDialogAction(
          label: 'Stay',
          value: false,
          icon: Icons.close_rounded,
          style: GameDialogActionStyle.secondary,
        ),
        GameDialogAction(
          label: 'Leave',
          value: true,
          icon: Icons.logout_rounded,
          style: GameDialogActionStyle.danger,
        ),
      ],
    );
    if (leave != true) {
      return;
    }
    await ref.read(sessionProvider.notifier).leave();
    if (mounted) {
      Navigator.popUntil(context, (r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final game = session.game;
    final turn = ref.watch(currentTurnProvider);
    final dice = ref.watch(diceProvider);

    ref.listen(sessionProvider, (prev, next) {
      final state = next.game;
      if (next.lastEvent != null && next.lastEvent != prev?.lastEvent) {
        _game.handleEvent(next.lastEvent!);
        if (next.lastEvent case DiceResultMessage(:final playerId)) {
          _lastRollerId = playerId;
          setState(() => _rolling = true);
          _game.diceRolling = true;
          Future<void>.delayed(TimingConstants.diceAnimation, () {
            _game.diceRolling = false;
            if (mounted) {
              setState(() => _rolling = false);
            }
          });
        }
        switch (next.lastEvent) {
          case TurnAutoPlayedMessage(:final playerId):
            final player = next.game?.playerById(playerId);
            _showBanner('Time up! Auto-played for ${player?.name ?? 'player'}');
          case TurnChangedMessage(reason: 'home', :final playerId):
            final player = next.game?.playerById(playerId);
            _showBanner('Token home! ${player?.name ?? 'Player'} rolls again');
          case TurnChangedMessage(reason: 'three_sixes'):
            final player = next.game?.playerById(_lastRollerId ?? '');
            _showBanner(
              'Three sixes! ${player?.name ?? 'Player'} loses the turn',
            );
          default:
            break;
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
        _showResultWhenSettled();
      }
      if (next.hostDisconnected && !(prev?.hostDisconnected ?? false)) {
        showGameDialog<void>(
          context: context,
          barrierDismissible: false,
          title: 'Host Disconnected',
          message: 'The host left the game. Returning to the menu.',
          actions: const [
            GameDialogAction(
              label: 'OK',
              value: null,
              icon: Icons.home_rounded,
            ),
          ],
        ).then((_) {
          if (context.mounted) {
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        });
      }
    });

    final players = {
      for (final color in PlayerColor.values)
        color: game?.players.where((p) => p.color == color).firstOrNull,
    };
    final currentId = game?.currentPlayerId;
    // Pass-and-play has no fixed "you"; every seat is on this device.
    final localId = session.isPassAndPlay ? null : session.localPlayerId;
    // Laid out for a ~763pt-tall safe area; shorter screens shrink the
    // header and dice so the board keeps most of the space.
    final media = MediaQuery.of(context);
    final usable = media.size.height - media.padding.vertical;
    final chromeScale = ((usable - 400) / 363).clamp(0.6, 1.0);

    Widget hudRow(PlayerColor left, PlayerColor right, {required bool top}) {
      Widget card(PlayerColor color) => _hudOrGap(
        players[color],
        isTurn: currentId != null && players[color]?.playerId == currentId,
        isLocal: players[color] != null && players[color]!.playerId == localId,
        pointerDown: top,
      );
      return Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, top ? 0 : 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: top
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [card(left), card(right)],
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _confirmLeave();
        }
      },
      child: GameBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _GameHeader(
                    scale: chromeScale,
                    turn: turn,
                    currentName: game?.currentPlayer?.name,
                    onBack: _confirmLeave,
                    onSettings: () => Navigator.pushNamed(context, '/settings'),
                  ),
                  hudRow(PlayerColor.green, PlayerColor.yellow, top: true),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: LudoFlameGame.aspectRatio,
                          child: GameWidget(game: _game),
                        ),
                      ),
                    ),
                  ),
                  hudRow(PlayerColor.red, PlayerColor.blue, top: false),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: GoldButton(
                            label: 'Leave',
                            icon: Icons.arrow_back_rounded,
                            onPressed: _confirmLeave,
                          ),
                        ),
                        const SizedBox(width: 2),
                        ValueListenableBuilder<bool>(
                          valueListenable: _game.busy,
                          builder: (context, busy, _) => _scaled(
                            chromeScale,
                            DiceWidget.size,
                            DiceWidget(
                              face: game?.diceValue ?? 1,
                              enabled: dice.enabled && !busy,
                              rolling: _rolling,
                              secondsRemaining:
                                  game?.status == GameStatus.active
                                  ? game!.turnTimerSecondsRemaining
                                  : null,
                              onRoll: () =>
                                  ref.read(sessionProvider.notifier).rollDice(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: GoldButton(
                            label: 'Menu',
                            icon: Icons.menu_rounded,
                            onPressed: () =>
                                setState(() => _menuOpen = !_menuOpen),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_banner != null)
                Positioned(
                  top: 150,
                  left: 40,
                  right: 40,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.navyPanel,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.gold, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Color(0x66000000), blurRadius: 10),
                        ],
                      ),
                      child: Text(
                        _banner!,
                        textAlign: TextAlign.center,
                        style: AppFonts.uiStyle(
                          size: 14,
                          weight: 900,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  ),
                ),
              if (_menuOpen)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => setState(() => _menuOpen = false),
                    child: Container(
                      color: const Color(0x99000000),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 60),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GoldButton(
                            label: 'Resume',
                            icon: Icons.play_arrow_rounded,
                            onPressed: () => setState(() => _menuOpen = false),
                          ),
                          const SizedBox(height: 14),
                          GoldButton(
                            label: 'Leave game',
                            icon: Icons.logout_rounded,
                            onPressed: () {
                              setState(() => _menuOpen = false);
                              _confirmLeave();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shrinks a fixed-size widget while keeping it tappable.
  static Widget _scaled(double scale, Size size, Widget child) {
    return SizedBox(
      width: size.width * scale,
      height: size.height * scale,
      child: FittedBox(
        child: SizedBox.fromSize(size: size, child: child),
      ),
    );
  }

  Widget _hudOrGap(
    PlayerState? player, {
    required bool isTurn,
    required bool isLocal,
    required bool pointerDown,
  }) {
    if (player == null) {
      return const SizedBox(width: 8);
    }
    return PlayerHudCard(
      player: player,
      isTurn: isTurn,
      isLocal: isLocal,
      compact: true,
      pointerDown: pointerDown,
    );
  }
}

/// Back / sound / settings buttons, the logo and the "whose turn" pill.
class _GameHeader extends ConsumerWidget {
  const _GameHeader({
    required this.scale,
    required this.turn,
    required this.currentName,
    required this.onBack,
    required this.onSettings,
  });

  final CurrentTurnView turn;
  final String? currentName;
  final VoidCallback onBack;
  final VoidCallback onSettings;
  final double scale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soundOn = ref.watch(soundEnabledProvider);
    return SizedBox(
      height: 136 * scale,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            left: 12,
            top: 4,
            child: HeaderIconButton(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Leave game',
              circle: true,
              onPressed: onBack,
            ),
          ),
          Positioned(
            right: 12,
            top: 4,
            child: Row(
              children: [
                HeaderIconButton(
                  icon: soundOn
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                  tooltip: soundOn ? 'Mute' : 'Unmute',
                  size: 38,
                  onPressed: () => ref
                      .read(soundEnabledProvider.notifier)
                      .update((on) => !on),
                ),
                const SizedBox(width: 10),
                HeaderIconButton(
                  icon: Icons.settings_rounded,
                  tooltip: 'Settings',
                  size: 38,
                  onPressed: onSettings,
                ),
              ],
            ),
          ),
          Positioned(
            top: 6 * scale,
            child: LudoLogo(size: 62 * scale),
          ),
          if (currentName != null)
            Positioned(
              top: 104 * scale,
              child: _TurnPill(turn: turn, name: currentName!),
            ),
        ],
      ),
    );
  }
}

class _TurnPill extends StatelessWidget {
  const _TurnPill({required this.turn, required this.name});

  final CurrentTurnView turn;
  final String name;

  @override
  Widget build(BuildContext context) {
    final white = AppFonts.uiStyle(
      size: 15.5,
      weight: 900,
      color: Colors.white,
    );
    final gold = white.copyWith(color: AppColors.gold);
    // Highlight the distinguishing part: "Player 1's" -> gold "1's".
    final split = name.lastIndexOf(' ');
    final spans = turn.isLocal
        ? [
            TextSpan(text: 'Your', style: gold),
            TextSpan(text: ' Turn', style: white),
          ]
        : [
            if (split > 0)
              TextSpan(text: name.substring(0, split + 1), style: white),
            TextSpan(text: "${name.substring(split + 1)}'s", style: gold),
            TextSpan(text: ' Turn', style: white),
          ];
    return Container(
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.navyPanel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.navyBorder, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Text.rich(
        TextSpan(children: spans),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
