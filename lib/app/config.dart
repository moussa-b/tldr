/// Build-time configuration (`--dart-define` / `--dart-define-from-file`,
/// see config/example.json).
class AppConfig {
  const AppConfig._();

  /// Reddit « installed app » client id (OAuth). Empty → threads are read
  /// through a WebView (lib/data/engine/reddit_page.dart).
  static const redditClientId = String.fromEnvironment('REDDIT_CLIENT_ID');

  /// Reddit asks for a descriptive User-Agent with the developer's username.
  static const redditUserAgent = String.fromEnvironment('REDDIT_USER_AGENT',
      defaultValue: 'android:com.bdzapps.tldr:v1.0.0 (by /u/tldr_plus_app)');
}
