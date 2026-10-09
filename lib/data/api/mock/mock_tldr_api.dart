import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../../../core/errors.dart';
import '../../../core/reddit_url.dart';
import '../../models/models.dart';
import '../tldr_api.dart';

/// Loads a fixture JSON file. Defaults to the app bundle; tests inject a
/// file-system loader.
typedef FixtureLoader = Future<String> Function(String path);

Future<String> bundleFixtureLoader(String path) =>
    rootBundle.loadString('assets/fixtures/api/$path');

/// Fake backend (`API_MODE=mock`, spec « Mock »). Fixtures in
/// assets/fixtures/api are validated against docs/api/openapi.yaml by
/// test/contract/fixtures_contract_test.dart.
///
/// Deterministic error triggers:
/// | Input                         | Error                    |
/// | URL contains `notfound`       | THREAD_NOT_FOUND          |
/// | URL contains `deleted`        | THREAD_UNAVAILABLE        |
/// | URL contains `/user/`,`/wiki/`| UNSUPPORTED_URL           |
/// | URL contains `ratelimit`      | RATE_LIMITED (120 s)      |
/// | URL contains `timeout`        | TIMEOUT                   |
/// | key == `invalid`              | LLM_KEY_INVALID           |
/// | key == `quota`                | LLM_QUOTA_EXCEEDED        |
/// | non-Reddit host               | INVALID_URL               |
class MockTldrApi implements TldrApi {
  MockTldrApi({
    FixtureLoader? loader,
    this.simulateLatency = true,
    Random? random,
  })  : _load = loader ?? bundleFixtureLoader,
        _random = random ?? Random();

  final FixtureLoader _load;
  final bool simulateLatency;
  final Random _random;

  /// Successful summaries by Idempotency-Key (replay, eng review R2).
  final Map<String, SummaryResult> _idempotent = {};

  /// Calls to [summarize] that reached the "LLM", for tests.
  int summarizeCalls = 0;

  static const successFixtures = [
    'summary_en_long.json',
    'summary_fr.json',
    'summary_link.json',
  ];

  Future<Map<String, dynamic>> _json(String path) async =>
      jsonDecode(await _load(path)) as Map<String, dynamic>;

  Future<Never> _fail(String fixture, {int? retryAfterSeconds}) async {
    final body = await _json('errors/$fixture');
    final error = ApiError.fromBody(body);
    throw ApiError(
      code: error.code,
      message: error.message,
      retryable: error.retryable,
      retryAfterSeconds: retryAfterSeconds ?? error.retryAfterSeconds,
      reason: error.reason,
    );
  }

  Future<void> _delay(int minMs, int maxMs, [ApiCancelToken? token]) async {
    if (!simulateLatency) return;
    final ms = minMs + _random.nextInt(max(1, maxMs - minMs));
    final completer = Completer<void>();
    final timer = Timer(Duration(milliseconds: ms), () {
      if (!completer.isCompleted) completer.complete();
    });
    token?.onCancel(() {
      timer.cancel();
      if (!completer.isCompleted) completer.completeError(ApiError.cancelled);
    });
    return completer.future;
  }

  @override
  Future<ProviderCatalog> getModels() async {
    await _delay(200, 400);
    return ProviderCatalog.fromJson(await _json('models.json'));
  }

  @override
  Future<KeyValidation> validateKey({
    required ProviderId provider,
    required String apiKey,
  }) async {
    await _delay(200, 400);
    final valid = apiKey.trim() != 'invalid';
    return KeyValidation(valid: valid, provider: provider);
  }

  @override
  Future<SummaryResult> summarize({
    required String url,
    required ProviderId provider,
    String? model,
    required String apiKey,
    required String idempotencyKey,
    ApiCancelToken? cancelToken,
  }) async {
    final replay = _idempotent[idempotencyKey];
    if (replay != null) {
      await _delay(200, 400, cancelToken);
      return replay;
    }
    final lower = url.toLowerCase();
    if (extractRedditUrl(url) == null) return _fail('invalid_url.json');
    if (apiKey.trim().isEmpty) {
      throw const ApiError(
          code: 'LLM_KEY_MISSING', message: 'Missing key', retryable: false);
    }
    await _delay(2000, 4000, cancelToken);
    if (lower.contains('notfound')) return _fail('thread_not_found.json');
    if (lower.contains('deleted')) return _fail('thread_unavailable.json');
    if (lower.contains('/user/') || lower.contains('/wiki/')) {
      return _fail('unsupported_url.json');
    }
    if (lower.contains('ratelimit')) {
      return _fail('rate_limited.json', retryAfterSeconds: 120);
    }
    if (lower.contains('timeout')) return _fail('timeout.json');
    if (apiKey.trim() == 'invalid') return _fail('llm_key_invalid.json');
    if (apiKey.trim() == 'quota') return _fail('llm_quota_exceeded.json');

    summarizeCalls++;
    final fixture = successFixtures[_stableHash(url) % successFixtures.length];
    final json = await _json(fixture);
    final meta = json['meta'] as Map<String, dynamic>;
    meta['provider'] = provider.name;
    if (model != null) meta['model'] = model;
    // The summary text is a fixture, but « Ouvrir dans Reddit » and the
    // history must point to the thread the user actually shared.
    final thread = json['thread'] as Map<String, dynamic>;
    final shared = extractRedditUrl(url)!;
    thread['permalink'] = shared;
    thread['id'] = extractPostId(shared) ?? thread['id'];
    thread['subreddit'] = extractSubreddit(shared) ?? thread['subreddit'];
    final result = SummaryResult.fromJson(json);
    _idempotent[idempotencyKey] = result;
    return result;
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
    if (apiKey.trim() == 'invalid') return _fail('llm_key_invalid.json');
    await _delay(1000, 2000);
    final translated = TranslationResult.fromJson(await _json('translation_fr.json'));
    // Keep the original verdict; only the three texts are translated.
    return TranslationResult(Analysis(
      language: targetLanguage,
      shortSummary: translated.analysis.shortSummary,
      detailedSummary: translated.analysis.detailedSummary,
      sentiment: analysis.sentiment,
      emotions: analysis.emotions,
      toxicity: analysis.toxicity,
      aiTake: translated.analysis.aiTake,
    ));
  }

  // String.hashCode is not stable across runs; fixtures must be.
  static int _stableHash(String value) {
    var hash = 0;
    for (final unit in value.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash;
  }
}
