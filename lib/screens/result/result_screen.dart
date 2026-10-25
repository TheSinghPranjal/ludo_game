import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../domain/models/game_state.dart';
import '../../game/tokens/marble_painter.dart';
import '../../state/providers/session_provider.dart';
import '../../state/session_state.dart';
import '../widgets/game_background.dart';
import '../widgets/ludo_logo.dart';
import 'victory_art.dart';

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen>
    with TickerProviderStateMixin {
  /// Drives rays, confetti and twinkles; repeats forever.
  late final _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  /// One-shot entrance: banner, then trophy, then standings rows.
  late final _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();

  @override
  void dispose() {
    _loop.dispose();
    _entry.dispose();
    super.dispose();
  }

  Animation<double> _interval(double begin, double end, Curve curve) =>
      CurvedAnimation(
        parent: _entry,
        curve: Interval(begin, end, curve: curve),
      );

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final game = session.game;
    final winner = game?.players
        .where((p) => p.playerId == game.winnerId)
        .firstOrNull;
    final standings = game == null ? <PlayerState>[] : _standings(game);

    final media = MediaQuery.of(context);
    final compact = media.size.height - media.padding.vertical < 720;
    final bannerIn = _interval(0, 0.4, Curves.easeOutBack);
    final trophyIn = _interval(0.15, 0.8, Curves.elasticOut);

    return GameBackground(
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _loop,
              builder: (context, _) =>
                  CustomPaint(painter: ConfettiPainter(_loop.value)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: compact ? 4 : 12),
                LudoLogo(size: compact ? 36 : 48),
                SizedBox(height: compact ? 2 : 8),
                ScaleTransition(
                  scale: bannerIn,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: VictoryBanner(
                      name: winner?.name,
                      height: compact ? 76 : 100,
                    ),
                  ),
                ),
                Expanded(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_loop, _entry]),
                    builder: (context, _) =>
                        TrophyScene(loop: _loop.value, pop: trophyIn.value),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      if (standings.isNotEmpty)
                        _StandingsPanel(
                          standings: standings,
                          winnerId: game?.winnerId,
                          compact: compact,
                          rowIn: (i) => _interval(
                            (0.45 + i * 0.1).clamp(0, 0.8),
                            (0.75 + i * 0.1).clamp(0, 1),
                            Curves.easeOutCubic,
                          ),
                        ),
                      SizedBox(height: compact ? 14 : 24),
                      GoldButton(
                        label: 'Play Again',
                        icon: Icons.refresh_rounded,
                        onPressed: () => _playAgain(session),
                      ),
                      SizedBox(height: compact ? 10 : 14),
                      GoldButton(
                        label: 'Exit',
                        icon: Icons.home_rounded,
                        onPressed: () async {
                          await ref.read(sessionProvider.notifier).leave();
                          if (context.mounted) {
                            Navigator.popUntil(context, (r) => r.isFirst);
                          }
                        },
                      ),
                      SizedBox(height: compact ? 10 : 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _playAgain(SessionState session) {
    if (session.isPassAndPlay) {
      ref.read(sessionProvider.notifier).playAgain();
      Navigator.popUntil(
        context,
        (r) => r.settings.name == '/game' || r.isFirst,
      );
      return;
    }
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
  }
}

class _StandingsPanel extends StatelessWidget {
  const _StandingsPanel({
    required this.standings,
    required this.winnerId,
    required this.compact,
    required this.rowIn,
  });

  final List<PlayerState> standings;
  final String? winnerId;
  final bool compact;
  final Animation<double> Function(int index) rowIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.navyPanel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.navyBorder, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          for (final (i, player) in standings.indexed) ...[
            if (i > 0) const SizedBox(height: 8),
            _animatedRow(
              rowIn(i),
              _StandingRow(
                player: player,
                place: player.rank ?? i + 1,
                isWinner: player.playerId == winnerId,
                height: compact ? 50 : 60,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _animatedRow(Animation<double> t, Widget child) {
    return FadeTransition(
      opacity: t,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0.25, 0),
          end: Offset.zero,
        ).animate(t),
        child: child,
      ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  const _StandingRow({
    required this.player,
    required this.place,
    required this.isWinner,
    required this.height,
  });

  final PlayerState player;
  final int place;
  final bool isWinner;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.only(left: 10, right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isWinner
              ? const [Color(0xFF2763D6), Color(0xFF143E9A)]
              : const [Color(0xFF123274), Color(0xFF0C2558)],
        ),
        border: Border.all(
          color: isWinner ? AppColors.gold : const Color(0x332F6FE6),
          width: isWinner ? 2.5 : 1.5,
        ),
        boxShadow: isWinner
            ? const [BoxShadow(color: AppColors.glow, blurRadius: 14)]
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: isWinner ? const CrownBadge(size: 32) : null,
          ),
          const SizedBox(width: 6),
          CustomPaint(
            size: Size.square(height * 0.68),
            painter: _MarbleIconPainter(player.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              player.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.uiStyle(
                size: height * 0.34,
                weight: 800,
                color: Colors.white,
              ),
            ),
          ),
          MedalBadge(place: place, size: height * 0.8),
        ],
      ),
    );
  }
}

class _MarbleIconPainter extends CustomPainter {
  _MarbleIconPainter(this.color);

  final PlayerColor color;

  @override
  void paint(Canvas canvas, Size size) {
    MarblePainter.paint(
      canvas,
      size.center(Offset.zero),
      size.width / 2,
      color,
    );
  }

  @override
  bool shouldRepaint(covariant _MarbleIconPainter old) => old.color != color;
}

List<PlayerState> _standings(GameState game) {
  final order = game.finishedOrder;
  int place(PlayerState p) {
    final i = order.indexOf(p.playerId);
    return i < 0 ? order.length : i;
  }

  return [...game.players]..sort((a, b) => place(a).compareTo(place(b)));
}
