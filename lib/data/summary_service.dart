import 'dart:convert';

import 'package:flutter/services.dart';

import '../core/errors.dart';
import '../core/reddit_url.dart';
import 'api/tldr_api.dart';
import 'db/summaries_dao.dart';
import 'models/models.dart';
import 'secure/key_store.dart';
import 'settings/settings_repository.dart';

/// Loads the catalog bundled with the app (spec D-4).
typedef CatalogAssetLoader = Future<String> Function();

Future<String> bundledCatalog() => rootBundle.loadString('assets/catalog.json');

/// A stored model replaced by the provider default (eng review R4).
class ModelFallback {
  const ModelFallback(this.provider, this.from, this.to);

  final ProviderId provider;
  final String from;
  final String to;
}

/// Orchestrates API, history, settings and keys. Screens talk to this.
class SummaryService {
  SummaryService({
    required this.api,
    required this.dao,
    required this.settings,
    required this.keys,
    CatalogAssetLoader? catalogAsset,
    DateTime Function()? clock,
  })  : _catalogAsset = catalogAsset ?? bundledCatalog,
        _clock = clock ?? DateTime.now;

  final TldrApi api;
  final SummariesDao dao;
  final SettingsRepository settings;
  final KeyStore keys;
  final CatalogAssetLoader _catalogAsset;
  final DateTime Function() _clock;

  // ---- Catalog --------------------------------------------------------------

  /// Cached catalog, or the bundled copy on first launch. Never network.
  Future<ProviderCatalog> catalog() async {
    final cached = await settings.cachedCatalog();
    if (cached != null) return cached;
    return ProviderCatalog.fromJson(
        jsonDecode(await _catalogAsset()) as Map<String, dynamic>);
  }

  /// Fetches the catalog from the engine, caches it and replaces stored
  /// models that disappeared. Failures keep the cache silently (spec D-4).
  Future<List<ModelFallback>> refreshCatalog() async {
    final ProviderCatalog fresh;
    try {
      fresh = await api.getModels();
    } on ApiError {
      return const [];
    }
    await settings.cacheCatalog(fresh);
    return reconcileModels(fresh);
  }

  Future<List<ModelFallback>> reconcileModels(ProviderCatalog catalog) async {
    final fallbacks = <ModelFallback>[];
    for (final provider in catalog.providers) {
      final stored = await settings.model(provider.id);
      if (stored != null && !provider.hasModel(stored)) {
        final replacement = provider.defaultModel.id;
        await settings.setModel(provider.id, replacement);
        fallbacks.add(ModelFallback(provider.id, stored, replacement));
      }
    }
    return fallbacks;
  }

  Future<String> effectiveModel(ProviderId provider) async {
    final catalog = await this.catalog();
    final stored = await settings.model(provider);
    final entry = catalog.provider(provider);
    if (stored != null && entry.hasModel(stored)) return stored;
    return entry.defaultModel.id;
  }

  Future<String> modelName(ProviderId provider, String modelId) async {
    final entry = (await catalog()).provider(provider);
    for (final m in entry.models) {
      if (m.id == modelId) return m.name;
    }
    return modelId;
  }

  // ---- Keys -----------------------------------------------------------------

  Future<bool> hasAnyKey() async {
    for (final p in ProviderId.values) {
      if (await keys.read(p) != null) return true;
    }
    return false;
  }

  Future<bool> hasKeyForActiveProvider() async =>
      await keys.read(await settings.activeProvider()) != null;

  /// Spec D-5: a refused key is not stored; a network error stores it unverified.
  Future<KeySaveResult> saveKey(ProviderId provider, String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) return KeySaveResult.empty;
    try {
      final result = await api.validateKey(provider: provider, apiKey: trimmed);
      if (!result.valid) return KeySaveResult.refused;
      await keys.write(provider, trimmed);
      return KeySaveResult.valid;
    } on ApiError {
      await keys.write(provider, trimmed);
      return KeySaveResult.unverified;
    }
  }

  // ---- Summaries ------------------------------------------------------------

  /// Existing entry for a shared/pasted link, checked before any call (spec D-10).
  Future<SummaryEntry?> findExisting(String url) async {
    final postId = extractPostId(url);
    if (postId != null) {
      final byThread = await dao.findByThreadId(postId);
      if (byThread != null) return byThread;
    }
    return dao.findBySourceUrl(url);
  }

  /// Creates the pending record, calls the API and stores the result.
  /// Replays once with a refreshed catalog on UNSUPPORTED_MODEL (eng review R4).
  Future<SummaryEntry> summarize(
    String url, {
    PendingSummary? resume,
    ApiCancelToken? cancelToken,
    void Function(List<ModelFallback>)? onModelFallback,
  }) async {
    final provider = resume?.provider ?? await settings.activeProvider();
    final apiKey = await keys.read(provider);
    if (apiKey == null) {
      throw const ApiError(
          code: 'LLM_KEY_MISSING', message: 'No key', retryable: false);
    }
    final pending = resume ??
        PendingSummary(
          url: url,
          provider: provider,
          model: await effectiveModel(provider),
          startedAt: _clock(),
        );
    await settings.setPendingSummary(pending);
    try {
      final result = await _summarizeWithModelRetry(
          pending, apiKey, cancelToken, onModelFallback);
      final entry = await dao.upsert(result, sourceUrl: url.trim());
      await settings.clearPendingSummary();
      return entry;
    } on ApiError catch (e) {
      if (!e.retryable) await settings.clearPendingSummary();
      rethrow;
    }
  }

  Future<SummaryResult> _summarizeWithModelRetry(
    PendingSummary pending,
    String apiKey,
    ApiCancelToken? cancelToken,
    void Function(List<ModelFallback>)? onModelFallback,
  ) async {
    try {
      return await api.summarize(
        url: pending.url,
        provider: pending.provider,
        model: pending.model,
        apiKey: apiKey,
        cancelToken: cancelToken,
      );
    } on ApiError catch (e) {
      if (e.code != 'UNSUPPORTED_MODEL') rethrow;
      final fallbacks = await refreshCatalog();
      onModelFallback?.call(fallbacks);
      return api.summarize(
        url: pending.url,
        provider: pending.provider,
        model: await effectiveModel(pending.provider),
        apiKey: apiKey,
        cancelToken: cancelToken,
      );
    }
  }

  /// Regenerates an entry with the active provider; the old row is only
  /// replaced on success (spec D-8).
  Future<SummaryEntry> regenerate(SummaryEntry entry) async {
    final provider = await settings.activeProvider();
    final apiKey = await keys.read(provider);
    if (apiKey == null) {
      throw const ApiError(
          code: 'LLM_KEY_MISSING', message: 'No key', retryable: false);
    }
    final result = await api.summarize(
      url: entry.thread.permalink,
      provider: provider,
      model: await effectiveModel(provider),
      apiKey: apiKey,
    );
    return dao.upsert(result, sourceUrl: entry.sourceUrl);
  }

  Future<SummaryEntry> translate(SummaryEntry entry) async {
    final provider = await settings.activeProvider();
    final apiKey = await keys.read(provider);
    if (apiKey == null) {
      throw const ApiError(
          code: 'LLM_KEY_MISSING', message: 'No key', retryable: false);
    }
    final result = await api.translate(
      analysis: entry.analysis,
      provider: provider,
      model: await effectiveModel(provider),
      apiKey: apiKey,
    );
    await dao.saveTranslation(entry.id, result.analysis);
    return (await dao.getById(entry.id))!;
  }

  Future<PendingSummary?> freshPending() async {
    final pending = await settings.pendingSummary();
    if (pending == null) return null;
    if (pending.isFresh(_clock())) return pending;
    await settings.clearPendingSummary();
    return null;
  }
}

enum KeySaveResult { valid, refused, unverified, empty }
