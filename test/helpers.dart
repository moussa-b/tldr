import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tldr/app/app.dart';
import 'package:tldr/app/providers.dart';
import 'package:tldr/app/theme.dart';
import 'package:tldr/data/api/mock/mock_tldr_api.dart';
import 'package:tldr/data/api/tldr_api.dart';
import 'package:tldr/data/db/app_database.dart';
import 'package:tldr/data/db/summaries_dao.dart';
import 'package:tldr/data/models/models.dart';
import 'package:tldr/data/secure/key_store.dart';
import 'package:tldr/data/settings/settings_repository.dart';
import 'package:tldr/data/summary_service.dart';
import 'package:tldr/features/home/home_screen.dart';
import 'package:tldr/features/share/share_intent_source.dart';

Future<String> fileFixture(String path) =>
    File('assets/fixtures/api/$path').readAsString();

Future<String> fileCatalog() => File('assets/catalog.json').readAsString();

Future<void> initTestEnv() async {
  sqfliteFfiInit();
  AppFonts.useGoogleFonts = false;
  await initializeDateFormatting('fr_FR');
}

Future<AppDatabase> openTestDb() =>
    AppDatabase.open(
        factory: databaseFactoryFfi, path: inMemoryDatabasePath, singleInstance: false);

MockTldrApi testMockApi() => MockTldrApi(loader: fileFixture, simulateLatency: false);

class TestDeps {
  TestDeps(this.db, this.api, this.keys)
      : dao = SummariesDao(db.db),
        settings = SettingsRepository(db.db);

  final AppDatabase db;
  final TldrApi api;
  final KeyStore keys;
  final SummariesDao dao;
  final SettingsRepository settings;

  SummaryService get service => SummaryService(
      api: api, dao: dao, settings: settings, keys: keys, catalogAsset: fileCatalog);

  List<Override> get overrides => [
        databaseProvider.overrideWithValue(db),
        apiProvider.overrideWithValue(api),
        keyStoreProvider.overrideWithValue(keys),
        settingsProvider.overrideWithValue(settings),
        summaryServiceProvider.overrideWithValue(service),
      ];
}

Future<TestDeps> testDeps({TldrApi? api, Map<ProviderId, String>? keys}) async =>
    TestDeps(await openTestDb(), api ?? testMockApi(),
        MemoryKeyStore(keys ?? {ProviderId.gemini: 'AIza-test-key'}));

/// Pumps the whole app. The DB work happens through sqflite_ffi on real I/O,
/// so [tester.runAsync] is used around pumps that wait on it.
Future<FakeShareIntentSource> pumpApp(WidgetTester tester, TestDeps deps,
    {String? initialShare}) async {
  HomeScreen.setupShownThisLaunch = false;
  final share = FakeShareIntentSource(initialText: initialShare);
  await tester.pumpWidget(ProviderScope(
    overrides: deps.overrides,
    child: TldrApp(shareSource: share),
  ));
  await settle(tester);
  return share;
}

/// Lets real async work (sqflite_ffi, fixture file reads) complete between frames.
Future<void> settle(WidgetTester tester, {int rounds = 20}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Widget wrapScreen(Widget child, TestDeps deps) => ProviderScope(
      overrides: deps.overrides,
      child: MaterialApp(theme: AppTheme.light(), home: child),
    );
