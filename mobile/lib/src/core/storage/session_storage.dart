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

  final SharedPreferences _preferences;

  Future<void> saveAuthToken(String token) async {
    await _preferences.setString(_authTokenKey, token);
  }

  String? getAuthToken() {
    return _preferences.getString(_authTokenKey);
  }

  Future<void> clear() async {
    await _preferences.remove(_authTokenKey);
  }
}
