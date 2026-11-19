import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Counts finished games and, when the player has earned it, asks the
/// store to show its in-app review prompt.
abstract class InAppReviewService {
  /// Called once a game has reached the winner/result screen.
  ///
  /// Never call this mid-game. Implementations must not throw.
  Future<void> onGameCompleted();
}

final inAppReviewServiceProvider = Provider<InAppReviewService>((ref) {
  return const NoopInAppReviewService();
});

/// Used in tests and whenever the store review API is not wired up.
class NoopInAppReviewService implements InAppReviewService {
  const NoopInAppReviewService();

  @override
  Future<void> onGameCompleted() async {}
}

/// Records completed games in [SharedPreferences] and requests a review
/// after the 3rd finished game, at most once every 30 days.
class StoreInAppReviewService implements InAppReviewService {
  StoreInAppReviewService({
    required SharedPreferences prefs,
    InAppReview? review,
    Future<bool> Function()? isAvailable,
    Future<void> Function()? requestReview,
    DateTime Function()? now,
  }) : _prefs = prefs,
       _isAvailable =
           isAvailable ??
           (() => (review ?? InAppReview.instance).isAvailable()),
       _requestReview =
           requestReview ??
           (() => (review ?? InAppReview.instance).requestReview()),
       _now = now ?? DateTime.now;

  final SharedPreferences _prefs;
  final Future<bool> Function() _isAvailable;
  final Future<void> Function() _requestReview;
  final DateTime Function() _now;

  static const completedGamesKey = 'in_app_review_completed_games';
  static const lastPromptAtKey = 'in_app_review_last_prompt_at';
  static const minCompletedGames = 3;
  static const cooldown = Duration(days: 30);

  @override
  Future<void> onGameCompleted() async {
    try {
      final completed = (_prefs.getInt(completedGamesKey) ?? 0) + 1;
      await _prefs.setInt(completedGamesKey, completed);
      if (completed < minCompletedGames) return;

      final lastMs = _prefs.getInt(lastPromptAtKey);
      if (lastMs != null) {
        final elapsed = _now().difference(
          DateTime.fromMillisecondsSinceEpoch(lastMs),
        );
        if (elapsed < cooldown) return;
      }

      if (!await _isAvailable()) return;

      await _requestReview();
      await _prefs.setInt(lastPromptAtKey, _now().millisecondsSinceEpoch);
    } catch (_) {
      // A store-API failure must never interrupt the result screen.
    }
  }
}
