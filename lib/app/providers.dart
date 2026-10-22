import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api/tldr_api.dart';
import '../data/db/app_database.dart';
import '../data/db/summaries_dao.dart';
import '../data/engine/direct_tldr_api.dart';
import '../data/engine/reddit_page.dart';
import '../data/engine/webview_reddit_client.dart';
import '../data/secure/key_store.dart';
import '../data/settings/settings_repository.dart';
import '../data/models/models.dart';
import '../data/summary_service.dart';
import '../l10n/app_language.dart';
import '../l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/widgets.dart';

/// Overridden in main() (and tests) with an opened database.
final databaseProvider = Provider<AppDatabase>(
    (ref) => throw UnimplementedError('databaseProvider must be overridden'));

final keyStoreProvider = Provider<KeyStore>((ref) => SecureKeyStore());

/// Reads Reddit and calls the user's AI provider, all on the device.
final apiProvider = Provider<TldrApi>((ref) {
  return DirectTldrApi(
    reddit: WebViewRedditClient(host: ref.watch(redditPageHostProvider)),
    catalog: () async => ProviderCatalog.fromJson(
        jsonDecode(await bundledCatalog()) as Map<String, dynamic>),
  );
});

/// Lets the Summary screen show the Reddit page the thread is read from.
/// Widget tests override it with null: no WebView, a skeleton instead.
final redditPageHostProvider = Provider<RedditPageHost?>((ref) => RedditPageHost());

final summariesDaoProvider =
    Provider<SummariesDao>((ref) => SummariesDao(ref.watch(databaseProvider).db));

final settingsProvider =
    Provider<SettingsRepository>((ref) => SettingsRepository(ref.watch(databaseProvider).db));

final summaryServiceProvider = Provider<SummaryService>((ref) => SummaryService(
      api: ref.watch(apiProvider),
      dao: ref.watch(summariesDaoProvider),
      settings: ref.watch(settingsProvider),
      keys: ref.watch(keyStoreProvider),
    ));

/// History list with pagination (spec D-2, eng review T9).
class HistoryState {
  const HistoryState({this.items = const [], this.hasMore = true, this.loading = false});

  final List<HistoryItem> items;
  final bool hasMore;
  final bool loading;
}

class HistoryNotifier extends Notifier<HistoryState> {
  @override
  HistoryState build() {
    Future.microtask(reload);
    return const HistoryState(loading: true);
  }

  SummariesDao get _dao => ref.read(summariesDaoProvider);

  Future<void> reload() async {
    final items = await _dao.page();
    state = HistoryState(items: items, hasMore: items.length == SummariesDao.pageSize);
  }

  Future<void> loadMore() async {
    if (state.loading || !state.hasMore) return;
    state = HistoryState(items: state.items, hasMore: true, loading: true);
    final next = await _dao.page(offset: state.items.length);
    state = HistoryState(
      items: [...state.items, ...next],
      hasMore: next.length == SummariesDao.pageSize,
    );
  }

  Future<SummaryEntry?> remove(String id) async {
    final entry = await _dao.delete(id);
    await reload();
    return entry;
  }

  Future<void> restore(SummaryEntry entry) async {
    await _dao.restore(entry);
    await reload();
  }

  Future<void> clearAll() async {
    await _dao.clear();
    await reload();
  }
}

/// Bumped whenever a key is saved or deleted, so a screen showing « add a
/// key » refreshes wherever the change happened.
class KeyRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final keyRevisionProvider = NotifierProvider<KeyRevision, int>(KeyRevision.new);

final historyProvider =
    NotifierProvider<HistoryNotifier, HistoryState>(HistoryNotifier.new);

/// The « Langue » setting as read before the first frame (main() overrides
/// it), so the first screen is already in the right language.
final initialAppLanguageProvider = Provider<AppLanguage>((ref) => AppLanguage.system);

class AppLanguageNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() => ref.read(initialAppLanguageProvider);

  /// Saved first: a choice that could not be saved is not shown either.
  Future<void> set(AppLanguage language) async {
    await ref.read(settingsProvider).setAppLanguage(language);
    state = language;
  }
}

final appLanguageProvider =
    NotifierProvider<AppLanguageNotifier, AppLanguage>(AppLanguageNotifier.new);

/// The device's languages, updated when they change while the app runs.
class DeviceLocales extends Notifier<List<Locale>> {
  @override
  List<Locale> build() => WidgetsBinding.instance.platformDispatcher.locales;

  void update(List<Locale> locales) => state = locales;
}

final deviceLocalesProvider =
    NotifierProvider<DeviceLocales, List<Locale>>(DeviceLocales.new);

/// The language the app shows.
final appLocaleProvider = Provider<Locale>((ref) =>
    resolveAppLocale(ref.watch(appLanguageProvider), ref.watch(deviceLocalesProvider)));

/// The installed version, shown in the settings.
final appVersionProvider =
    FutureProvider<String>((ref) async => (await PackageInfo.fromPlatform()).version);

/// The app's texts outside the widget tree (snackbars of the root widget).
final appLocalizationsProvider =
    Provider<AppLocalizations>((ref) => lookupAppLocalizations(ref.watch(appLocaleProvider)));
