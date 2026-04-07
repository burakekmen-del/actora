import 'package:flutter/foundation.dart';

class FirebaseBootstrap {
  static Future<bool> initialize() async {
    if (kDebugMode) {
      debugPrint('Firebase is disabled in this MVP build.');
    }
    return false;
  }
}
