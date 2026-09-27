class ApiConfig {
  const ApiConfig._();

  /// Local development backend.
  ///
  /// For Chrome running on the same Windows machine:
  /// http://localhost:4000
  ///
  /// Change this later for the production API domain.
  static const String baseUrl = 'http://localhost:4000/api/v1';

  static String get storageBaseUrl => '$baseUrl/storage';
}
