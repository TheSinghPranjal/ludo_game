import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_game/domain/models/player_color.dart';
import 'package:ludo_game/domain/models/player_state.dart';
import 'package:ludo_game/screens/widgets/player_card.dart';

void main() {
  // A card that resizes when its turn starts shifts the board below it.
  testWidgets('HUD card keeps the same size whether or not it is its turn', (
    tester,
  ) async {
    Future<Size> sizeOf({
      required bool isTurn,
      required bool isLocal,
      required bool connected,
      required bool pointerDown,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: PlayerHudCard(
              key: const Key('card'),
              player: PlayerState(
                playerId: 'p',
                name: 'Player 1',
                color: PlayerColor.green,
                isReady: true,
                isConnected: connected,
                isHost: false,
                isAi: false,
                reconnectToken: 'p',
              ),
              isTurn: isTurn,
              isLocal: isLocal,
              compact: true,
              pointerDown: pointerDown,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.getSize(find.byKey(const Key('card')));
    }

    for (final pointerDown in [true, false]) {
      for (final isLocal in [true, false]) {
        final idle = await sizeOf(
          isTurn: false,
          isLocal: isLocal,
          connected: true,
          pointerDown: pointerDown,
        );
        for (final (isTurn, connected) in [(true, true), (false, false)]) {
          expect(
            await sizeOf(
              isTurn: isTurn,
              isLocal: isLocal,
              connected: connected,
              pointerDown: pointerDown,
            ),
            idle,
            reason: 'isTurn=$isTurn connected=$connected local=$isLocal',
          );
        }
      }
    }
  });
}
