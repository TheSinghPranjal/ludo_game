import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../domain/models/player_color.dart';
import '../../domain/models/player_state.dart';

class PlayerHudCard extends StatelessWidget {
  const PlayerHudCard({
    super.key,
    required this.player,
    required this.isTurn,
    required this.isLocal,
    this.compact = false,
  });

  final PlayerState player;
  final bool isTurn;
  final bool isLocal;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.of(player.color);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isTurn ? color : color.withValues(alpha: 0.45),
          width: isTurn ? 2.4 : 1.2,
        ),
        boxShadow: isTurn
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 16,
                ),
              ]
            : const [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: compact ? 16 : 20,
            backgroundColor: color,
            child: const Icon(Icons.person_rounded, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isLocal ? '${player.name} (You)' : player.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: player.isConnected ? color : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isTurn
                        ? (isLocal ? 'YOUR TURN' : 'Playing')
                        : player.isConnected
                            ? player.color.displayName
                            : 'Away',
                    style: TextStyle(
                      color: isTurn ? AppColors.gold : AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
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
            color: selected ? AppColors.of(color) : AppColors.of(color).withValues(alpha: 0.4),
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
                  color: player!.isReady ? AppColors.green : AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
