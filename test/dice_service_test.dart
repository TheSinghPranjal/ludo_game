import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_game/services/dice_service.dart';

void main() {
  test('secure dice only returns 1 through 6', () {
    const dice = SecureDiceService();
    for (var i = 0; i < 200; i++) {
      final value = dice.secureRoll();
      expect(value, inInclusiveRange(1, 6));
    }
  });

  test('scripted dice returns the programmed sequence', () {
    final dice = ScriptedDiceService([1, 6, 3]);
    expect(dice.secureRoll(), 1);
    expect(dice.secureRoll(), 6);
    expect(dice.secureRoll(), 3);
  });
}
