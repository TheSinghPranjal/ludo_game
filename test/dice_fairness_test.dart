import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_game/services/dice_service.dart';

void main() {
  test(
    'secure dice distribution is approximately uniform',
    () {
      const dice = SecureDiceService();
      const rolls = 300000;
      final counts = List<int>.filled(7, 0);
      var previous = 0;
      var sequentialRun = 0;
      var maxSequential = 0;

      for (var i = 0; i < rolls; i++) {
        final value = dice.secureRoll();
        counts[value]++;
        if (value == previous % 6 + 1) {
          sequentialRun++;
          if (sequentialRun > maxSequential) {
            maxSequential = sequentialRun;
          }
        } else {
          sequentialRun = 1;
        }
        previous = value;
      }

      for (var face = 1; face <= 6; face++) {
        expect(
          counts[face],
          greaterThan(0),
          reason: 'face $face never appeared',
        );
        final expected = rolls / 6;
        final delta = (counts[face] - expected).abs() / expected;
        expect(
          delta,
          lessThan(0.08),
          reason: 'face $face was ${counts[face]} of $rolls (delta $delta)',
        );
      }

      // A true 1,2,3,4,5,6,1,... generator would produce a long sequential run.
      expect(maxSequential, lessThan(20));
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
