import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'data/db/app_database.dart';
import 'data/settings/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  final database = await AppDatabase.open();
  final settings = SettingsRepository(database.db);
  await settings.init();
  runApp(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(database),
      settingsProvider.overrideWithValue(settings),
    ],
    child: const TldrApp(),
  ));
}
