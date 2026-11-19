import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_game/services/review/in_app_review_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeReviewApi {
  bool available = true;
  bool shouldThrow = false;
  int requestCount = 0;
  int availabilityChecks = 0;

  Future<bool> isAvailable() async {
    availabilityChecks++;
    if (shouldThrow) throw StateError('unavailable');
    return available;
  }

  Future<void> requestReview() async {
    if (shouldThrow) throw StateError('request failed');
    requestCount++;
  }
}

void main() {
  late _FakeReviewApi api;
  late SharedPreferences prefs;
  late DateTime now;
  late StoreInAppReviewService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    api = _FakeReviewApi();
    now = DateTime(2026, 11, 18, 12);
    service = StoreInAppReviewService(
      prefs: prefs,
      isAvailable: api.isAvailable,
      requestReview: api.requestReview,
      now: () => now,
    );
  });

  test('does not prompt before the third completed game', () async {
    await service.onGameCompleted();
    await service.onGameCompleted();
    expect(api.requestCount, 0);
    expect(api.availabilityChecks, 0);
    await service.onGameCompleted();
    expect(api.requestCount, 1);
  });

  test('does not prompt again within 30 days', () async {
    await service.onGameCompleted();
    await service.onGameCompleted();
    await service.onGameCompleted();
    expect(api.requestCount, 1);

    await service.onGameCompleted();
    now = now.add(const Duration(days: 29));
    await service.onGameCompleted();
    expect(api.requestCount, 1);

    now = now.add(const Duration(days: 1));
    await service.onGameCompleted();
    expect(api.requestCount, 2);
  });

  test('skips the prompt when the store API is unavailable', () async {
    api.available = false;
    await service.onGameCompleted();
    await service.onGameCompleted();
    await service.onGameCompleted();
    expect(api.requestCount, 0);

    api.available = true;
    await service.onGameCompleted();
    expect(api.requestCount, 1);
  });

  test('swallows store API errors and does not start the cooldown', () async {
    api.shouldThrow = true;
    await service.onGameCompleted();
    await service.onGameCompleted();
    await expectLater(service.onGameCompleted(), completes);
    expect(api.requestCount, 0);
    expect(prefs.getInt(StoreInAppReviewService.lastPromptAtKey), isNull);
  });
}
