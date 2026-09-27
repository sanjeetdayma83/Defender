class ApiConfig {
  const ApiConfig._();

  /// Override in production with:
  /// flutter build web --dart-define=API_BASE_URL=https://YOUR_API_DOMAIN/api/v1
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:4000/api/v1',
  );

  static String get storageBaseUrl => '$baseUrl/storage';
}
