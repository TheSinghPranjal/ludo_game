import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../state/providers/session_provider.dart';

/// Development-only overlay. Never mounted on the production game screen.
class DebugPanel extends ConsumerWidget {
  const DebugPanel({super.key});

  static const enabled = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kDebugMode || !enabled) {
      return const SizedBox.shrink();
    }
    final session = ref.watch(sessionProvider);
    final game = session.game;
    if (game == null) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(8),
        color: const Color(0xAA000000),
        child: DefaultTextStyle(
          style: const TextStyle(color: AppColors.gold, fontSize: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                session.isHost
                    ? 'HOST'
                    : session.isPassAndPlay
                    ? 'HOTSEAT'
                    : 'CLIENT',
              ),
              Text('rev ${game.revision} turn ${game.turnNumber}'),
              Text('player ${game.currentPlayer?.color.name ?? "-"}'),
              Text('dice ${game.diceValue ?? "-"} rolled=${game.diceRolled}'),
              Text('moves ${game.validMoves.join(",")}'),
              Text('conn ${session.connection.name}'),
            ],
          ),
        ),
      ),
    );
  }
}
