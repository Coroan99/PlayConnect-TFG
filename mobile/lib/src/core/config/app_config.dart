class AppConfig {
  const AppConfig._();

  static const appName = 'PlayConnect';

  static const _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  static const enableNetworkLogs = bool.fromEnvironment('NETWORK_LOGS');

  static String get apiBaseUrl {
    return _apiBaseUrl.endsWith('/') ? _apiBaseUrl : '$_apiBaseUrl/';
  }
}
