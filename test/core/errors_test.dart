import 'package:flutter_test/flutter_test.dart';
import 'package:tldr/core/errors.dart';
import 'package:tldr/l10n/app_localizations.dart';
import 'dart:ui';

void main() {
  const codes = [
    'INVALID_URL', 'LLM_KEY_MISSING', 'UNSUPPORTED_MODEL',
    'THREAD_NOT_FOUND', 'THREAD_UNAVAILABLE', 'UNSUPPORTED_URL',
    'THREAD_EMPTY', 'LLM_KEY_INVALID', 'LLM_MODEL_UNAVAILABLE',
    'LLM_QUOTA_EXCEEDED', 'LLM_OUTPUT_INVALID', 'LLM_UNAVAILABLE', 'REDDIT_UNAVAILABLE',
    'TIMEOUT', 'NETWORK_ERROR',
  ];
  const generic = 'Une erreur est survenue';
  final fr = lookupAppLocalizations(const Locale('fr'));

  test('every user-facing code has a specific French message', () {
    for (final code in codes) {
      final copy = errorCopy(ApiError(code: code, message: 'x', retryable: false), fr);
      expect(copy.title, isNot(generic), reason: code);
      expect(copy.body, isNotEmpty, reason: code);
    }
  });

  test('THREAD_UNAVAILABLE copy depends on the reason', () {
    final titles = {
      for (final r in ['deleted', 'removed', 'private', 'quarantined', 'banned'])
        r: errorCopy(
                ApiError(code: 'THREAD_UNAVAILABLE', message: '', retryable: false, reason: r), fr)
            .title,
    };
    expect(titles.values.toSet(), hasLength(5));
  });

  // protects=every error has its own English copy too, and a generic provider name;
  // fails_when=an English code falls back to the generic message; no_claim=the wording.
  test('every user-facing code has a specific English message', () {
    final en = lookupAppLocalizations(const Locale('en'));
    for (final code in codes) {
      final copy = errorCopy(ApiError(code: code, message: 'x', retryable: false), en);
      expect(copy.title, isNot(en.errorGenericTitle), reason: code);
      expect(copy.body, isNotEmpty, reason: code);
    }
    final titles = {
      for (final r in ['deleted', 'removed', 'private', 'quarantined', 'banned'])
        errorCopy(ApiError(code: 'THREAD_UNAVAILABLE', message: '', retryable: false, reason: r), en)
            .title,
    };
    expect(titles, hasLength(5));
    expect(
        errorCopy(const ApiError(code: 'LLM_UNAVAILABLE', message: '', retryable: true), en).title,
        "AI provider isn't responding");
  });

  test('only a quota error counts down before retrying', () {
    const quota = ApiError(
        code: 'LLM_QUOTA_EXCEEDED', message: 'q', retryable: true, retryAfterSeconds: 60);
    expect(quota.hasCountdown, isTrue);
    expect(quota.isKeyProblem, isFalse);
    expect(ApiError.timeout.hasCountdown, isFalse);
  });
}
