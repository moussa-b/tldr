/// Build-time configuration (`--dart-define` / `--dart-define-from-file`,
/// see config/example.json).
class AppConfig {
  const AppConfig._();

  /// `direct` (device talks to Reddit and the AI provider) or `mock`.
  /// A future `backend` mode would plug an HTTP `TldrApi` here.
  static const apiMode = String.fromEnvironment('API_MODE', defaultValue: 'direct');

  /// Reddit « installed app » client id. Empty → public .json endpoints.
  static const redditClientId = String.fromEnvironment('REDDIT_CLIENT_ID');

  /// Reddit asks for a descriptive User-Agent with the developer's username.
  static const redditUserAgent = String.fromEnvironment('REDDIT_USER_AGENT',
      defaultValue: 'android:com.bdzapps.tldr:v1.0.0 (by /u/tldr_plus_app)');

  static bool get isMock => apiMode == 'mock';
}
