class ClerkConfig {
  const ClerkConfig._();

  static const publishableKey = String.fromEnvironment(
    'CLERK_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  static bool get isConfigured =>
      publishableKey.trim().isNotEmpty && publishableKey.startsWith('pk_');
}
