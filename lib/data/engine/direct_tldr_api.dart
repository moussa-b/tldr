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

/// [TldrApi] running entirely on the device (`API_MODE=direct`): reads Reddit,
/// selects comments and calls the user's AI provider. Same error codes and
/// behaviour as the former backend contract (spec « Révision 2026-10-09 »).
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
    required String idempotencyKey,
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

    final analysis = await _generate(
      provider: provider,
      started: started,
      dioToken: dioToken,
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
        model: modelId,
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
    final texts = await _generate(
      provider: provider,
      started: started,
      dioToken: CancelToken(),
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

  /// One call, plus one retry with the validation error if ≥ 25 s remain
  /// (eng review R1).
  Future<T> _generate<T>({
    required ProviderId provider,
    required DateTime started,
    required CancelToken dioToken,
    required LlmRequest request,
    required T Function(Map<String, dynamic>) parse,
  }) async {
    final client = _llmFor(provider);
    var current = request;
    for (var attempt = 0; attempt < 2; attempt++) {
      final remaining = _remaining(started);
      if (remaining <= Duration.zero) throw ApiError.timeout;
      final timed = LlmRequest(
        model: current.model,
        apiKey: current.apiKey,
        system: current.system,
        user: current.user,
        schema: current.schema,
        geminiSchema: current.geminiSchema,
        toolName: current.toolName,
        timeout: remaining < current.timeout ? remaining : current.timeout,
      );
      try {
        final raw = await client
            .generateJson(timed, cancelToken: dioToken)
            .timeout(remaining, onTimeout: () {
          dioToken.cancel();
          throw ApiError.timeout;
        });
        return parse(raw);
      } on FormatException catch (e) {
        if (attempt == 1 || _remaining(started) < _minTimeForRetry) {
          throw const ApiError(
              code: 'LLM_OUTPUT_INVALID',
              message: 'Model output did not match the schema',
              retryable: true);
        }
        current = LlmRequest(
          model: request.model,
          apiKey: request.apiKey,
          system: request.system,
          user: '${request.user}\n\nYour previous answer was invalid: ${e.message}. '
              'Return a corrected JSON object.',
          schema: request.schema,
          geminiSchema: request.geminiSchema,
          toolName: request.toolName,
        );
      }
    }
    throw const ApiError(
        code: 'LLM_OUTPUT_INVALID', message: 'Unreachable', retryable: true);
  }

  Duration _remaining(DateTime started) => deadline - _clock().difference(started);

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
