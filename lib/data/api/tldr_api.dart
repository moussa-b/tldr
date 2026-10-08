import '../models/models.dart';

/// The only boundary between the UI and « how a summary is produced ».
/// Every method throws `ApiError` on failure, using the error codes of the spec.
///
/// Implementations (selected by `API_MODE`, see lib/app/providers.dart):
/// - `DirectTldrApi` (`direct`): everything on the device — Reddit + the
///   user's AI provider (lib/data/engine/).
/// - `MockTldrApi` (`mock`): fixtures, for development and tests.
/// - Future `BackendTldrApi` (`backend`): an HTTP client to a server
///   implementing the same operations (the former contract lives in the git
///   history: docs/api/openapi.yaml at commit c006290). Parameters such as
///   [summarize]'s `idempotencyKey` are kept for that case.
abstract interface class TldrApi {
  Future<ProviderCatalog> getModels();

  Future<KeyValidation> validateKey({
    required ProviderId provider,
    required String apiKey,
  });

  /// [idempotencyKey] lets a retry after the app was suspended reuse the
  /// server-side result instead of paying a second LLM call (eng review R2).
  Future<SummaryResult> summarize({
    required String url,
    required ProviderId provider,
    String? model,
    required String apiKey,
    required String idempotencyKey,
    ApiCancelToken? cancelToken,
  });

  Future<TranslationResult> translate({
    required Analysis analysis,
    required ProviderId provider,
    String? model,
    required String apiKey,
    String targetLanguage = 'fr',
  });
}

/// Transport-agnostic cancellation (wraps dio's CancelToken in the live client).
class ApiCancelToken {
  final List<void Function()> _listeners = [];
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }

  void onCancel(void Function() listener) {
    if (_cancelled) {
      listener();
    } else {
      _listeners.add(listener);
    }
  }
}
