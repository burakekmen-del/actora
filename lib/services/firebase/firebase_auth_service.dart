import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>(
  (ref) => FirebaseAuthService(),
);

class FirebaseAuthService {
  static const String _userIdKey = 'local_user_id';

  Future<AppUser> ensureAnonymousUser() async {
    final prefs = await SharedPreferences.getInstance();
    final currentId = prefs.getString(_userIdKey);
    if (currentId != null && currentId.isNotEmpty) {
      return AppUser(uid: currentId);
    }

    final generatedId =
        'local_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1 << 32)}';
    await prefs.setString(_userIdKey, generatedId);
    return AppUser(uid: generatedId);
  }

  Future<AppUser?> get currentUser async {
    final prefs = await SharedPreferences.getInstance();
    final currentId = prefs.getString(_userIdKey);
    if (currentId == null || currentId.isEmpty) {
      return null;
    }
    return AppUser(uid: currentId);
  }

  Stream<AppUser?> authStateChanges() async* {
    yield await currentUser;
  }
}

class AppUser {
  const AppUser({required this.uid});

  final String uid;
}
