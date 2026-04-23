import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be provided at startup.');
});

final sessionStorageProvider = Provider<SessionStorage>((ref) {
  return SessionStorage(ref.watch(sharedPreferencesProvider));
});

class SessionStorage {
  SessionStorage(this._preferences);

  static const _authTokenKey = 'auth_token';
  static const _authUserKey = 'auth_user';

  final SharedPreferences _preferences;

  Future<void> saveSession({
    required String token,
    required Map<String, Object?> usuario,
  }) async {
    await Future.wait([
      _preferences.setString(_authTokenKey, token),
      _preferences.setString(_authUserKey, jsonEncode(usuario)),
    ]);
  }

  String? getAuthToken() {
    return _preferences.getString(_authTokenKey);
  }

  Map<String, Object?>? getAuthUser() {
    final rawUser = _preferences.getString(_authUserKey);

    if (rawUser == null || rawUser.isEmpty) {
      return null;
    }

    try {
      final decodedUser = jsonDecode(rawUser);

      if (decodedUser is Map) {
        return Map<String, Object?>.from(decodedUser);
      }
    } on FormatException {
      return null;
    }

    return null;
  }

  Future<void> clear() async {
    await Future.wait([
      _preferences.remove(_authTokenKey),
      _preferences.remove(_authUserKey),
    ]);
  }
}
