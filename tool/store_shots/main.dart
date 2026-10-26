import 'package:flutter/widgets.dart';
import 'package:tldr/data/models/models.dart';
import 'package:tldr/data/secure/key_store.dart';
import 'package:tldr/main.dart' as app;

/// The real app with a Gemini key already saved, for the store screenshots
/// (store/raw/): skips the setup screens. Run it with
///
/// ```
/// fvm flutter run -d <device> -t tool/store_shots/main.dart \
///   --dart-define=GEMINI_KEY="$(head -1 gemini.keys)"
/// ```
///
/// then reinstall the real app (`fvm flutter run -d <device> --no-resident`).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const key = String.fromEnvironment('GEMINI_KEY');
  if (key.isNotEmpty) await SecureKeyStore().write(ProviderId.gemini, key);
  await app.main();
}
