import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../domain/models/player_color.dart';
import '../../domain/models/player_state.dart';
import 'ludo_logo.dart';

class PlayerHudCard extends StatelessWidget {
  const PlayerHudCard({
    super.key,
    required this.player,
    required this.isTurn,
    required this.isLocal,
    this.compact = false,
    this.pointerTowardBoard = true,
    this.pointerDown = true,
  });

  final PlayerState player;
  final bool isTurn;
  final bool isLocal;
  final bool compact;
  final bool pointerTowardBoard;

  /// True when the board is below this card (top row), false when above.
  final bool pointerDown;

  /// Space reserved above the card for the crown, so turns don't shift layout.
  static const crownSpace = 16.0;
  static const pointerSize = Size(16, 8);

  @override
  Widget build(BuildContext context) {
    final color = AppColors.of(player.color);
    final showPointer = isTurn && pointerTowardBoard;
    final pointer = SizedBox.fromSize(
      size: pointerSize,
      child: showPointer
          ? CustomPaint(painter: _PointerPainter(color, down: pointerDown))
          : null,
    );

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: EdgeInsets.fromLTRB(5, 5, compact ? 14 : 18, 5),
      decoration: BoxDecoration(
        color: AppColors.navyPanel,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isTurn
              ? Color.lerp(color, Colors.white, 0.15)!
              : color.withValues(alpha: 0.85),
          // Fixed width: a thicker border on turn would resize the card and
          // shift the board.
          width: 3,
        ),
        boxShadow: [
          if (isTurn)
            BoxShadow(color: color.withValues(alpha: 0.75), blurRadius: 14),
          const BoxShadow(
            color: Color(0x55000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 36 : 42,
            height: compact ? 36 : 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(color, Colors.white, 0.15)!,
                  AppColors.deepOf(player.color),
                ],
              ),
              border: Border.all(color: const Color(0x55FFFFFF), width: 1.5),
            ),
            child: Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: compact ? 24 : 28,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Text(
                  isLocal ? '${player.name} (You)' : player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.uiStyle(
                    size: compact ? 14.5 : 16,
                    weight: 900,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
              ),
              const SizedBox(height: 1),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: player.isConnected ? color : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _StableLabel(
                    current: isTurn
                        ? (isLocal ? 'Your turn' : 'Playing')
                        : player.isConnected
                        ? player.color.displayName
                        : 'Away',
                    options: [
                      isLocal ? 'Your turn' : 'Playing',
                      player.color.displayName,
                      'Away',
                    ],
                    style: AppFonts.uiStyle(
                      size: 12.5,
                      weight: 800,
                      color: isTurn
                          ? AppColors.playingText
                          : AppColors.subtleText,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pointerDown) const SizedBox(height: crownSpace),
            if (!pointerDown) ...[
              SizedBox(height: crownSpace - pointerSize.height),
              pointer,
            ],
            card,
            if (pointerDown) pointer,
          ],
        ),
        if (isTurn)
          Positioned(
            left: 4,
            top: pointerDown ? -2 : -4,
            child: Transform.rotate(
              angle: -0.26,
              child: const CrownBadge(size: 30),
            ),
          ),
      ],
    );
  }
}

/// Shows [current] but always takes the size of the widest of [options],
/// so swapping the status line never resizes the card.
class _StableLabel extends StatelessWidget {
  const _StableLabel({
    required this.current,
    required this.options,
    required this.style,
  });

  final String current;
  final List<String> options;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final option in options)
          if (option != current)
            ExcludeSemantics(
              child: Opacity(
                opacity: 0,
                child: Text(option, maxLines: 1, style: style),
              ),
            ),
        Text(current, maxLines: 1, style: style),
      ],
    );
  }
}

class _PointerPainter extends CustomPainter {
  _PointerPainter(this.color, {required this.down});

  final Color color;
  final bool down;

  @override
  void paint(Canvas canvas, Size size) {
    final path = down
        ? (Path()
            ..moveTo(0, 0)
            ..lineTo(size.width, 0)
            ..lineTo(size.width / 2, size.height))
        : (Path()
            ..moveTo(0, size.height)
            ..lineTo(size.width, size.height)
            ..lineTo(size.width / 2, 0));
    canvas.drawPath(path..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PointerPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.down != down;
}

class LobbyPlayerTile extends StatelessWidget {
  const LobbyPlayerTile({
    super.key,
    required this.color,
    this.player,
    this.selected = false,
    this.onTap,
  });

  final PlayerColor color;
  final PlayerState? player;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.of(color)
                : AppColors.of(color).withValues(alpha: 0.4),
            width: selected ? 2.4 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.of(color),
              child: const Icon(Icons.person_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    color.displayName,
                    style: TextStyle(
                      color: AppColors.of(color),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    player?.name ?? 'Empty slot',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            if (player != null)
              Text(
                player!.isReady ? 'Ready' : 'Not ready',
                style: TextStyle(
                  color: player!.isReady
                      ? AppColors.green
                      : AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
