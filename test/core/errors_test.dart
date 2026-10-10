import 'package:flutter_test/flutter_test.dart';
import 'package:tldr/core/errors.dart';

void main() {
  const codes = [
    'INVALID_URL', 'LLM_KEY_MISSING', 'UNSUPPORTED_MODEL',
    'THREAD_NOT_FOUND', 'THREAD_UNAVAILABLE', 'UNSUPPORTED_URL',
    'THREAD_EMPTY', 'LLM_KEY_INVALID', 'LLM_MODEL_UNAVAILABLE',
    'LLM_QUOTA_EXCEEDED', 'LLM_OUTPUT_INVALID', 'LLM_UNAVAILABLE', 'REDDIT_UNAVAILABLE',
    'TIMEOUT', 'NETWORK_ERROR',
  ];
  const generic = 'Une erreur est survenue';

  test('every user-facing code has a specific French message', () {
    for (final code in codes) {
      final copy = errorCopy(ApiError(code: code, message: 'x', retryable: false));
      expect(copy.title, isNot(generic), reason: code);
      expect(copy.body, isNotEmpty, reason: code);
    }
  });

  test('THREAD_UNAVAILABLE copy depends on the reason', () {
    final titles = {
      for (final r in ['deleted', 'removed', 'private', 'quarantined', 'banned'])
        r: errorCopy(ApiError(code: 'THREAD_UNAVAILABLE', message: '', retryable: false, reason: r)).title,
    };
    expect(titles.values.toSet(), hasLength(5));
  });

  test('only a quota error counts down before retrying', () {
    const quota = ApiError(
        code: 'LLM_QUOTA_EXCEEDED', message: 'q', retryable: true, retryAfterSeconds: 60);
    expect(quota.hasCountdown, isTrue);
    expect(quota.isKeyProblem, isFalse);
    expect(ApiError.timeout.hasCountdown, isFalse);
  });
}
