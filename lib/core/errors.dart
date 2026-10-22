import '../l10n/app_localizations.dart';

/// Error surfaced by [TldrApi]. `code` is one of the error codes of the spec
/// (« Codes d'erreur »).
class ApiError implements Exception {
  const ApiError({
    required this.code,
    required this.message,
    required this.retryable,
    this.retryAfterSeconds,
    this.reason,
  });

  final String code;
  final String message;
  final bool retryable;
  final int? retryAfterSeconds;

  /// Why a thread is unavailable, or why Reddit refused (`blocked`).
  final String? reason;

  static const network = ApiError(
      code: 'NETWORK_ERROR', message: 'Network error', retryable: true);
  static const timeout =
      ApiError(code: 'TIMEOUT', message: 'Client timeout', retryable: true);
  static const cancelled =
      ApiError(code: 'CANCELLED', message: 'Cancelled', retryable: false);

  /// Errors the user fixes in the settings (spec D-7).
  bool get isKeyProblem => const {
        'LLM_KEY_INVALID',
        'LLM_KEY_MISSING',
        'LLM_MODEL_UNAVAILABLE',
      }.contains(code);

  bool get hasCountdown => code == 'LLM_QUOTA_EXCEEDED';

  @override
  String toString() => 'ApiError($code: $message)';
}

/// Copy shown to the user for one error (spec D-7).
class ErrorCopy {
  const ErrorCopy(this.title, this.body);

  final String title;
  final String body;
}

/// [providerLabel] names the AI provider; without it, a generic name.
ErrorCopy errorCopy(ApiError error, AppLocalizations l, {String? providerLabel}) {
  final provider = providerLabel ?? l.errorProviderFallback;
  switch (error.code) {
    case 'LLM_QUOTA_EXCEEDED':
      return ErrorCopy(l.errorQuotaTitle, l.errorQuotaBody(provider));
    case 'THREAD_UNAVAILABLE':
      return switch (error.reason) {
        'removed' => ErrorCopy(l.errorRemovedTitle, l.errorRemovedBody),
        'private' => ErrorCopy(l.errorPrivateTitle, l.errorPrivateBody),
        'quarantined' => ErrorCopy(l.errorQuarantinedTitle, l.errorQuarantinedBody),
        'banned' => ErrorCopy(l.errorBannedTitle, l.errorBannedBody),
        _ => ErrorCopy(l.errorDeletedTitle, l.errorDeletedBody),
      };
    case 'THREAD_NOT_FOUND':
      return ErrorCopy(l.errorNotFoundTitle, l.errorNotFoundBody);
    case 'UNSUPPORTED_URL':
      return ErrorCopy(l.errorUnsupportedUrlTitle, l.errorUnsupportedUrlBody);
    case 'INVALID_URL':
      return ErrorCopy(l.errorInvalidUrlTitle, l.errorInvalidUrlBody);
    case 'THREAD_EMPTY':
      return ErrorCopy(l.errorEmptyTitle, l.errorEmptyBody);
    case 'LLM_KEY_INVALID':
      return ErrorCopy(l.errorKeyInvalidTitle(provider), l.errorKeyInvalidBody);
    case 'LLM_KEY_MISSING':
      return ErrorCopy(l.errorKeyMissingTitle(provider), l.errorKeyMissingBody);
    case 'LLM_MODEL_UNAVAILABLE':
    case 'UNSUPPORTED_MODEL':
      return ErrorCopy(l.errorModelUnavailableTitle, l.errorModelUnavailableBody);
    case 'TIMEOUT':
      return ErrorCopy(l.errorTimeoutTitle, l.errorTimeoutBody);
    case 'NETWORK_ERROR':
      return ErrorCopy(l.errorNetworkTitle, l.errorNetworkBody);
    case 'LLM_UNAVAILABLE':
      return ErrorCopy(l.errorLlmUnavailableTitle(provider), l.errorLlmUnavailableBody);
    case 'LLM_OUTPUT_INVALID':
      return ErrorCopy(l.errorOutputInvalidTitle, l.errorOutputInvalidBody);
    case 'REDDIT_UNAVAILABLE':
      if (error.reason == 'blocked') {
        return ErrorCopy(l.errorRedditBlockedTitle, l.errorRedditBlockedBody);
      }
      return ErrorCopy(l.errorRedditUnavailableTitle, l.errorRedditUnavailableBody);
    default:
      return ErrorCopy(l.errorGenericTitle, l.errorGenericBody);
  }
}
