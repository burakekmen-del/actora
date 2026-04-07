import 'package:flutter/foundation.dart';

class FirebaseMessagingService {
  Future<String?> initialize() async {
    if (kDebugMode) {
      debugPrint('FCM is disabled in this MVP build.');
    }
    return null;
  }
}
