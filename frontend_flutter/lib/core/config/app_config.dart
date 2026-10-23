class AppConfig {
  AppConfig._();

  static const _configuredApiUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static String get apiBaseUrl =>
      _configuredApiUrl.trim().replaceFirst(RegExp(r'/+$'), '');
}
