import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'services/review/in_app_review_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
  final prefs = await SharedPreferences.getInstance();
  final inAppReview = StoreInAppReviewService(prefs: prefs);
  runApp(
    ProviderScope(
      overrides: [
        inAppReviewServiceProvider.overrideWithValue(inAppReview),
      ],
      child: const LudoApp(),
    ),
  );
}
