import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'data/db/app_database.dart';
import 'data/settings/settings_repository.dart';
import 'l10n/app_language.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The bundled fonts ship with their SIL Open Font License.
  LicenseRegistry.addLicense(() async* {
    for (final (font, file) in [('IBM Plex Sans', 'OFL-IBMPlexSans'), ('Literata', 'OFL-Literata')]) {
      yield LicenseEntryWithLineBreaks([font], await rootBundle.loadString('assets/fonts/$file.txt'));
    }
  });
  await initializeDateFormatting();
  final database = await AppDatabase.open();
  // The language is only a preference: a failed read follows the device.
  final language = await SettingsRepository(database.db)
      .appLanguageAtStartup(WidgetsBinding.instance.platformDispatcher.locales)
      .catchError((Object _) => AppLanguage.system);
  runApp(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(database),
      initialAppLanguageProvider.overrideWithValue(language),
    ],
    child: const TldrApp(),
  ));
}
