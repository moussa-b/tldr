import '../models/models.dart';

/// The only boundary between the UI and « how a summary is produced »:
/// `DirectTldrApi` (lib/data/engine/) in the app, a fake in the tests.
/// Every method throws `ApiError` on failure, using the error codes of the spec.
abstract interface class TldrApi {
  Future<ProviderCatalog> getModels();

  Future<KeyValidation> validateKey({
    required ProviderId provider,
    required String apiKey,
  });

  Future<SummaryResult> summarize({
    required String url,
    required ProviderId provider,
    String? model,
    required String apiKey,
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

/// Cancellation the UI can hold without knowing about dio.
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
