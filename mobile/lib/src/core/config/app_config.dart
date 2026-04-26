import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig._();

  static const appName = 'PlayConnect';

  static const _configuredApiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static const enableNetworkLogs = bool.fromEnvironment('NETWORK_LOGS');

  static String get apiBaseUrl {
    final baseUrl = _configuredApiBaseUrl.trim().isNotEmpty
        ? _configuredApiBaseUrl
        : _defaultApiBaseUrl;

    return baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
  }

  static String get _defaultApiBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }

    return 'http://localhost:3000/api';
  }
}
