import 'dart:convert';
import 'dart:io';

import 'package:tldr/core/errors.dart';
import 'package:tldr/core/reddit_url.dart';
import 'package:tldr/data/api/tldr_api.dart';
import 'package:tldr/data/models/models.dart';

/// [TldrApi] for tests: answers instantly with a fixture summary, or with the
/// error a URL fragment or a key asks for.
///
/// | Input                    | Error                      |
/// | URL contains `notfound`  | THREAD_NOT_FOUND           |
/// | URL contains `deleted`   | THREAD_UNAVAILABLE         |
/// | URL contains `timeout`   | TIMEOUT                    |
/// | key == `invalid`         | LLM_KEY_INVALID (refused)  |
/// | key == `quota`           | LLM_QUOTA_EXCEEDED         |
/// | non-Reddit URL           | INVALID_URL                |
class FakeTldrApi implements TldrApi {
  /// Calls to [summarize] that reached the « AI ».
  int summarizeCalls = 0;

  static const _summaries = [
    'test/fixtures/summary_en_long.json',
    'assets/demo/summary_fr.json',
    'test/fixtures/summary_link.json',
  ];

  static Map<String, dynamic> _json(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  @override
  Future<ProviderCatalog> getModels() async =>
      ProviderCatalog.fromJson(_json('assets/catalog.json'));

  @override
  Future<KeyValidation> validateKey({required ProviderId provider, required String apiKey}) async =>
      KeyValidation(valid: apiKey.trim() != 'invalid', provider: provider);

  @override
  Future<SummaryResult> summarize({
    required String url,
    required ProviderId provider,
    String? model,
    required String apiKey,
    ApiCancelToken? cancelToken,
  }) async {
    final shared = extractRedditUrl(url);
    if (shared == null) throw _error('INVALID_URL');
    final lower = url.toLowerCase();
    if (lower.contains('notfound')) throw _error('THREAD_NOT_FOUND');
    if (lower.contains('deleted')) throw _error('THREAD_UNAVAILABLE', reason: 'deleted');
    if (lower.contains('timeout')) throw ApiError.timeout;
    if (apiKey.trim() == 'invalid') throw _error('LLM_KEY_INVALID');
    if (apiKey.trim() == 'quota') {
      throw const ApiError(
          code: 'LLM_QUOTA_EXCEEDED', message: 'Quota', retryable: true, retryAfterSeconds: 60);
    }

    summarizeCalls++;
    final json = _json(_summaries[_stableHash(url) % _summaries.length]);
    final meta = json['meta'] as Map<String, dynamic>;
    meta['provider'] = provider.name;
    if (model != null) meta['model'] = model;
    // History and « Ouvrir dans Reddit » must point to the shared thread.
    final thread = json['thread'] as Map<String, dynamic>;
    thread['permalink'] = shared;
    thread['id'] = extractPostId(shared) ?? thread['id'];
    thread['subreddit'] = extractSubreddit(shared) ?? thread['subreddit'];
    return SummaryResult.fromJson(json);
  }

  @override
  Future<TranslationResult> translate({
    required Analysis analysis,
    required ProviderId provider,
    String? model,
    required String apiKey,
    String targetLanguage = 'fr',
  }) async {
    if (analysis.language == targetLanguage) return TranslationResult(analysis);
    if (apiKey.trim() == 'invalid') throw _error('LLM_KEY_INVALID');
    final texts = TranslationResult.fromJson(_json('test/fixtures/translation_fr.json')).analysis;
    // Only the three texts are translated; the verdict stays.
    return TranslationResult(Analysis(
      language: targetLanguage,
      shortSummary: texts.shortSummary,
      detailedSummary: texts.detailedSummary,
      sentiment: analysis.sentiment,
      emotions: analysis.emotions,
      toxicity: analysis.toxicity,
      aiTake: texts.aiTake,
    ));
  }

  static ApiError _error(String code, {String? reason}) =>
      ApiError(code: code, message: code, retryable: false, reason: reason);

  // String.hashCode is not stable across runs; the fixture choice must be.
  static int _stableHash(String value) {
    var hash = 0;
    for (final unit in value.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash;
  }
}
