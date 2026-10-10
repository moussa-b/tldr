import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api/mock/mock_tldr_api.dart';
import '../data/api/tldr_api.dart';
import '../data/db/app_database.dart';
import '../data/db/summaries_dao.dart';
import '../data/engine/direct_tldr_api.dart';
import '../data/engine/reddit_client.dart';
import '../data/engine/webview_reddit_client.dart';
import '../data/secure/key_store.dart';
import '../data/settings/settings_repository.dart';
import '../data/models/models.dart';
import '../data/summary_service.dart';
import 'config.dart';

/// Overridden in main() (and tests) with an opened database.
final databaseProvider = Provider<AppDatabase>(
    (ref) => throw UnimplementedError('databaseProvider must be overridden'));

final keyStoreProvider = Provider<KeyStore>((ref) => SecureKeyStore());

/// Swap point for a future backend: return a `BackendTldrApi` here.
final apiProvider = Provider<TldrApi>((ref) {
  if (AppConfig.isMock) return MockTldrApi();
  final settings = ref.watch(settingsProvider);
  return DirectTldrApi(
    // No approved Reddit app yet: read the public .json through a WebView.
    reddit: AppConfig.redditClientId.isEmpty
        ? WebViewRedditClient()
        : LiveRedditClient(
            clientId: AppConfig.redditClientId,
            userAgent: AppConfig.redditUserAgent,
            deviceId: () => settings.deviceIdSync,
          ),
    catalog: () async => ProviderCatalog.fromJson(
        jsonDecode(await bundledCatalog()) as Map<String, dynamic>),
  );
});

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

final historyProvider =
    NotifierProvider<HistoryNotifier, HistoryState>(HistoryNotifier.new);
