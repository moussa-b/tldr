import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tldr/core/errors.dart';
import 'package:tldr/core/labels.dart';
import 'package:tldr/l10n/app_localizations.dart';

/// The French app reads exactly as 1.0.2 did: these strings were captured
/// from 1.0.2 (b4564ba) before its texts moved to lib/l10n/app_fr.arb.
void main() {
  setUpAll(initializeDateFormatting);
  final fr = lookupAppLocalizations(const Locale('fr'));
  final now = DateTime(2026, 10, 11, 10, 55);

  test('numbers, percentages and dates match 1.0.2', () {
    expect(compactNumber(1234, fr), "1,23\u00a0k");
    expect(compactNumber(56789, fr), "56,8\u00a0k");
    expect(compactNumber(999, fr), "999");
    expect(compactNumber(1500000, fr), "1,5\u00a0M");
    expect(percent(0.45, fr), "45 %");
    expect(relativeDate(DateTime(2026, 10, 1), fr, now: now), "1 oct.");
    expect(relativeDate(DateTime(2025, 3, 7), fr, now: now), "7 mars 2025");
  });

  test('every error message matches 1.0.2', () {
    final cases = <(ApiError, String?, String, String)>[
      (ApiError(code: "INVALID_URL", message: '', retryable: false), 'Gemini', "Ce lien n'est pas un thread Reddit", "Partage ou colle un lien vers un post Reddit."),
      (ApiError(code: "LLM_KEY_MISSING", message: '', retryable: false), 'Gemini', "Aucune cl\u00e9 Gemini", "Ajoute ta cl\u00e9 IA pour lancer un r\u00e9sum\u00e9."),
      (ApiError(code: "UNSUPPORTED_MODEL", message: '', retryable: false), 'Gemini', "Mod\u00e8le indisponible", "Choisis un autre mod\u00e8le dans les r\u00e9glages."),
      (ApiError(code: "THREAD_NOT_FOUND", message: '', retryable: false), 'Gemini', "Thread introuvable", "Reddit ne trouve pas ce post. V\u00e9rifie le lien."),
      (ApiError(code: "UNSUPPORTED_URL", message: '', retryable: false), 'Gemini', "Ce lien n'est pas un thread", "TL;DR+ r\u00e9sume les posts Reddit, pas les profils ni les subreddits."),
      (ApiError(code: "THREAD_EMPTY", message: '', retryable: false), 'Gemini', "Rien \u00e0 r\u00e9sumer", "Ce post n'a ni texte ni commentaires exploitables."),
      (ApiError(code: "LLM_KEY_INVALID", message: '', retryable: false), 'Gemini', "Ta cl\u00e9 Gemini est refus\u00e9e", "V\u00e9rifie ou remplace ta cl\u00e9 dans les r\u00e9glages."),
      (ApiError(code: "LLM_MODEL_UNAVAILABLE", message: '', retryable: false), 'Gemini', "Mod\u00e8le indisponible", "Choisis un autre mod\u00e8le dans les r\u00e9glages."),
      (ApiError(code: "LLM_QUOTA_EXCEEDED", message: '', retryable: false), 'Gemini', "Quota du fournisseur atteint", "Ton quota Gemini est \u00e9puis\u00e9 pour le moment."),
      (ApiError(code: "LLM_OUTPUT_INVALID", message: '', retryable: false), 'Gemini', "R\u00e9ponse de l'IA inutilisable", "L'IA a renvoy\u00e9 un r\u00e9sultat incomplet. R\u00e9essaie."),
      (ApiError(code: "LLM_UNAVAILABLE", message: '', retryable: false), 'Gemini', "Gemini ne r\u00e9pond pas", "Le fournisseur IA est indisponible pour le moment."),
      (ApiError(code: "REDDIT_UNAVAILABLE", message: '', retryable: false), 'Gemini', "Reddit ne r\u00e9pond pas", "Reddit est indisponible pour le moment. R\u00e9essaie."),
      (ApiError(code: "TIMEOUT", message: '', retryable: false), 'Gemini', "C'est trop long", "Le r\u00e9sum\u00e9 n'a pas abouti \u00e0 temps. R\u00e9essaie dans un moment."),
      (ApiError(code: "NETWORK_ERROR", message: '', retryable: false), 'Gemini', "Pas de connexion", "V\u00e9rifie ta connexion internet puis r\u00e9essaie."),
      (ApiError(code: "OTHER", message: '', retryable: false), 'Gemini', "Une erreur est survenue", "R\u00e9essaie dans un moment."),
      (ApiError(code: "THREAD_UNAVAILABLE", message: '', retryable: false, reason: "deleted"), null, "Ce post a \u00e9t\u00e9 supprim\u00e9", "Il n'y a plus rien \u00e0 r\u00e9sumer."),
      (ApiError(code: "THREAD_UNAVAILABLE", message: '', retryable: false, reason: "removed"), null, "Post retir\u00e9 par la mod\u00e9ration", "Ce thread n'est plus disponible sur Reddit."),
      (ApiError(code: "THREAD_UNAVAILABLE", message: '', retryable: false, reason: "private"), null, "Ce subreddit est priv\u00e9", "Seuls ses membres peuvent lire ce thread."),
      (ApiError(code: "THREAD_UNAVAILABLE", message: '', retryable: false, reason: "quarantined"), null, "Subreddit en quarantaine", "Reddit restreint l'acc\u00e8s \u00e0 ce subreddit."),
      (ApiError(code: "THREAD_UNAVAILABLE", message: '', retryable: false, reason: "banned"), null, "Subreddit banni", "Ce subreddit n'existe plus sur Reddit."),
      (ApiError(code: "REDDIT_UNAVAILABLE", message: '', retryable: false, reason: "blocked"), null, "Reddit refuse l'acc\u00e8s", "Reddit bloque temporairement la lecture de ce thread. R\u00e9essaie dans quelques minutes."),
      (ApiError(code: "LLM_UNAVAILABLE", message: '', retryable: false), null, "le fournisseur ne r\u00e9pond pas", "Le fournisseur IA est indisponible pour le moment."),
    ];
    for (final (error, provider, title, body) in cases) {
      final copy = errorCopy(error, fr, providerLabel: provider);
      expect(copy.title, title, reason: '${error.code} ${error.reason}');
      expect(copy.body, body, reason: '${error.code} ${error.reason}');
    }
  });
}
