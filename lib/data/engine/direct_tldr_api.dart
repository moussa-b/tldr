import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/errors.dart';
import '../api/tldr_api.dart';
import '../models/models.dart';
import 'comment_selector.dart';
import 'llm_client.dart';
import 'prompts.dart';
import 'reddit_client.dart';

/// [TldrApi] running entirely on the device: reads Reddit, selects comments
/// and calls the user's AI provider (spec « Moteur sur l'appareil »).
class DirectTldrApi implements TldrApi {
  DirectTldrApi({
    required this.reddit,
    required this._catalog,
    Dio? dio,
    LlmClient Function(ProviderId provider)? llmFor,
    DateTime Function()? clock,
  })  : _clock = clock ?? DateTime.now,
        _llmFor = llmFor ?? ((p) => llmClientFor(p, dio ?? Dio()));

  final RedditClient reddit;
  final Future<ProviderCatalog> Function() _catalog;
  final LlmClient Function(ProviderId provider) _llmFor;
  final DateTime Function() _clock;

  static const deadline = Duration(seconds: 90);
  static const _minTimeForRetry = Duration(seconds: 25);
  // What the first call leaves the fallback: its 25 s plus slack, since the
  // first call ends a few ms after its budget.
  static const _fallbackReserve = Duration(seconds: 27);

  @override
  Future<ProviderCatalog> getModels() => _catalog();

  @override
  Future<KeyValidation> validateKey({
    required ProviderId provider,
    required String apiKey,
  }) async {
    final valid = await _llmFor(provider).validateKey(apiKey.trim());
    return KeyValidation(valid: valid, provider: provider);
  }

  @override
  Future<SummaryResult> summarize({
    required String url,
    required ProviderId provider,
    String? model,
    required String apiKey,
    ApiCancelToken? cancelToken,
  }) async {
    final started = _clock();
    final dioToken = CancelToken();
    cancelToken?.onCancel(dioToken.cancel);
    final modelId = await _resolveModel(provider, model);

    Future<T> withDeadline<T>(Future<T> future) =>
        future.timeout(_remaining(started), onTimeout: () {
          dioToken.cancel();
          throw ApiError.timeout;
        });

    final fetched = await withDeadline(reddit.fetch(url, cancelToken: dioToken));
    final selection = selectComments(fetched.comments);
    if (selection.analyzed == 0 && fetched.selftext.trim().isEmpty) {
      throw const ApiError(
          code: 'THREAD_EMPTY', message: 'Nothing to summarize', retryable: false);
    }

    final (analysis, usedModel) = await _generate(
      provider: provider,
      started: started,
      dioToken: dioToken,
      fallbackModel: await _fallbackModel(provider),
      request: LlmRequest(
        model: modelId,
        apiKey: apiKey.trim(),
        system: summarySystemPrompt,
        user: buildSummaryUserMessage(fetched.thread, fetched.selftext, selection),
        schema: analysisJsonSchema(),
        geminiSchema: analysisGeminiSchema(),
        toolName: 'submit_analysis',
      ),
      parse: parseAnalysisOutput,
    );

    return SummaryResult(
      thread: fetched.thread,
      analysis: analysis,
      meta: SummaryMeta(
        provider: provider,
        model: usedModel,
        commentsAnalyzed: selection.analyzed,
        commentsTotal: fetched.thread.numComments,
        truncated: selection.truncated,
      ),
    );
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
    final started = _clock();
    final (texts, _) = await _generate(
      provider: provider,
      started: started,
      dioToken: CancelToken(),
      fallbackModel: await _fallbackModel(provider),
      request: LlmRequest(
        model: await _resolveModel(provider, model),
        apiKey: apiKey.trim(),
        system: translateSystemPrompt(targetLanguage),
        user: '<analysis>${jsonEncode({
          'shortSummary': analysis.shortSummary,
          'detailedSummary': analysis.detailedSummary,
          'aiTake': analysis.aiTake,
        })}</analysis>',
        schema: translationJsonSchema(),
        geminiSchema: translationGeminiSchema(),
        toolName: 'submit_translation',
      ),
      parse: (raw) {
        String text(String key) {
          final v = raw[key];
          if (v is! String || v.trim().isEmpty) throw FormatException('"$key" missing');
          return v.trim();
        }

        return Analysis(
          language: targetLanguage,
          shortSummary: text('shortSummary'),
          detailedSummary: text('detailedSummary'),
          sentiment: analysis.sentiment,
          emotions: analysis.emotions,
          toxicity: analysis.toxicity,
          aiTake: text('aiTake'),
        );
      },
    );
    return TranslationResult(texts);
  }

  /// One call to the request's model, plus at most:
  /// - one call to [fallbackModel] if that model is overloaded (5xx), out of
  ///   quota or does not answer in time; the first call leaves it 25 s (plus
  ///   slack) when it can;
  /// - one retry with the validation error if the output does not validate.
  /// Each extra call needs ≥ 25 s left (eng review R1). Returns the result and
  /// the model that produced it.
  Future<(T, String)> _generate<T>({
    required ProviderId provider,
    required DateTime started,
    required CancelToken dioToken,
    required LlmRequest request,
    required String? fallbackModel,
    required T Function(Map<String, dynamic>) parse,
  }) async {
    final client = _llmFor(provider);
    var current = request;
    var fellBack = fallbackModel == null || fallbackModel == request.model;
    var corrected = false;
    while (true) {
      final remaining = _remaining(started);
      if (remaining <= Duration.zero) throw ApiError.timeout;
      if (dioToken.isCancelled) throw ApiError.cancelled;
      var budget = !fellBack && remaining - _fallbackReserve >= _minTimeForRetry
          ? remaining - _fallbackReserve
          : remaining;
      if (current.timeout < budget) budget = current.timeout;
      // Its own token: giving up on this call must not cancel the next one.
      final callToken = CancelToken();
      dioToken.whenCancel.then((_) => callToken.cancel());
      try {
        final raw = await client
            .generateJson(current.copyWith(timeout: budget), cancelToken: callToken)
            .timeout(budget, onTimeout: () {
          callToken.cancel();
          throw ApiError.timeout;
        });
        return (parse(raw), current.model);
      } on ApiError catch (e) {
        // A free-tier quota is counted per model: the fallback has its own.
        const handOver = {'LLM_UNAVAILABLE', 'TIMEOUT', 'LLM_QUOTA_EXCEEDED'};
        if (!handOver.contains(e.code) ||
            fellBack ||
            dioToken.isCancelled ||
            _remaining(started) < _minTimeForRetry) {
          rethrow;
        }
        fellBack = true;
        current = current.copyWith(model: fallbackModel);
      } on FormatException catch (e) {
        if (corrected || _remaining(started) < _minTimeForRetry) {
          throw const ApiError(
              code: 'LLM_OUTPUT_INVALID',
              message: 'Model output did not match the schema',
              retryable: true);
        }
        corrected = true;
        current = current.copyWith(
            user: '${request.user}\n\nYour previous answer was invalid: ${e.message}. '
                'Return a corrected JSON object.');
      }
    }
  }

  Duration _remaining(DateTime started) => deadline - _clock().difference(started);

  Future<String?> _fallbackModel(ProviderId provider) async =>
      (await _catalog()).provider(provider).fallbackModel;

  Future<String> _resolveModel(ProviderId provider, String? model) async {
    final entry = (await _catalog()).provider(provider);
    if (model == null) return entry.defaultModel.id;
    if (!entry.hasModel(model)) {
      throw const ApiError(
          code: 'UNSUPPORTED_MODEL', message: 'Unknown model for provider', retryable: false);
    }
    return model;
  }
}
