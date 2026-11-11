import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_game/app.dart';
import 'package:ludo_game/core/constants.dart';
import 'package:ludo_game/screens/splash/splash_screen.dart';

void main() {
  testWidgets('splash shows the app name and studio byline', (tester) async {
    await _pumpSplash(tester, const Size(390, 844), Brightness.dark);
    await tester.pump(TimingConstants.splashEntrance);

    expect(find.text('Ludo Game'), findsOneWidget);
    expect(find.text('by'), findsOneWidget);
    expect(find.text('The Lazy Bear Club'), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/branding/lazy_bear_club.png')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('byline stays on screen in light theme and on small phones', (
    tester,
  ) async {
    await _pumpSplash(
      tester,
      const Size(320, 568),
      Brightness.light,
      textScale: 1.6,
      padding: const FakeViewPadding(top: 44, bottom: 34),
    );
    await tester.pump(TimingConstants.splashEntrance);

    expect(find.text('Ludo Game'), findsOneWidget);
    expect(find.text('by'), findsOneWidget);
    expect(find.text('The Lazy Bear Club'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final name = tester.widget<Text>(find.text('The Lazy Bear Club'));
    expect(name.style?.color, AppColors.textPrimary);
  });

  testWidgets('byline fits a tablet', (tester) async {
    await _pumpSplash(tester, const Size(1024, 1366), Brightness.dark);
    await tester.pump(TimingConstants.splashEntrance);

    expect(find.text('The Lazy Bear Club'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('splash gives way to the home screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LudoApp()));
    expect(find.text('Ludo Game'), findsOneWidget);
    expect(find.text('PLAY ON THIS DEVICE'), findsNothing);

    await tester.pump(TimingConstants.splashHold);
    await tester.pumpAndSettle();

    expect(find.text('Ludo Game'), findsNothing);
    expect(find.text('by'), findsNothing);
    expect(find.text('PLAY ON THIS DEVICE'), findsOneWidget);
  });
}

Future<void> _pumpSplash(
  WidgetTester tester,
  Size size,
  Brightness brightness, {
  double textScale = 1,
  FakeViewPadding padding = FakeViewPadding.zero,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = padding;
  tester.view.viewPadding = padding;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        brightness: brightness,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.gold,
          brightness: brightness,
        ),
        fontFamily: AppFonts.ui,
      ),
      home: const SplashScreen(hold: Duration(days: 1)),
    ),
  );
}
