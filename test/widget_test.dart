import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_game/app.dart';

void main() {
  testWidgets('home screen shows local multiplayer', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LudoApp()));
    expect(find.text('LOCAL MULTIPLAYER'), findsOneWidget);
    expect(find.text('SETTINGS'), findsOneWidget);
  });
}
