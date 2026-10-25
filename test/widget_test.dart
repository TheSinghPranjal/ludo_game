import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_game/app.dart';
import 'package:ludo_game/core/constants.dart';
import 'package:ludo_game/screens/widgets/dice_widget.dart';
import 'package:ludo_game/state/providers/session_provider.dart';

void main() {
  testWidgets('home screen shows both play modes', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LudoApp()));
    expect(find.text('PLAY ON THIS DEVICE'), findsOneWidget);
    expect(find.text('WI-FI MULTIPLAYER'), findsOneWidget);
    expect(find.text('SETTINGS'), findsOneWidget);
  });

  testWidgets('pass-and-play: start, roll, and leave', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: LudoApp()));
    await tester.tap(find.text('PLAY ON THIS DEVICE'));
    await tester.pumpAndSettle();

    // Two players sit opposite each other: green and blue.
    expect(find.text('Green'), findsOneWidget);
    expect(find.text('Blue'), findsOneWidget);
    expect(find.text('Yellow'), findsNothing);

    await tester.tap(find.text('START GAME'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text("Player 1's Turn", findRichText: true), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(DiceWidget)),
    );
    expect(container.read(sessionProvider).game!.canRoll, isTrue);

    await tester.tap(find.byType(DiceWidget));
    await tester.pump();
    expect(
      container.read(sessionProvider).game!.diceRolled ||
          container.read(sessionProvider).game!.currentPlayerId != 'hotseat-0',
      isTrue,
    );
    await tester.pump(TimingConstants.diceAnimation);
    await tester.pump(const Duration(seconds: 2));

    // Back gesture asks before abandoning the game.
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Leave Game?'), findsOneWidget);
    await tester.tap(find.text('Leave').last);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('PLAY ON THIS DEVICE'), findsOneWidget);
    expect(container.read(sessionProvider).game, isNull);
  });
}
