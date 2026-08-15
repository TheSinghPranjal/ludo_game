import 'package:flutter/foundation.dart';

void debugLog(String event, [Map<String, Object?> data = const {}]) {
  if (!kDebugMode) {
    return;
  }
  if (data.isEmpty) {
    debugPrint('[LUDO] $event');
  } else {
    debugPrint('[LUDO] $event $data');
  }
}
