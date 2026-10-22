// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get languageName => 'Français';

  @override
  String get errorProviderFallback => 'le fournisseur';

  @override
  String get errorQuotaTitle => 'Quota du fournisseur atteint';

  @override
  String errorQuotaBody(String provider) {
    return 'Ton quota $provider est épuisé pour le moment.';
  }

  @override
  String get errorRemovedTitle => 'Post retiré par la modération';

  @override
  String get errorRemovedBody => 'Ce thread n\'est plus disponible sur Reddit.';

  @override
  String get errorPrivateTitle => 'Ce subreddit est privé';

  @override
  String get errorPrivateBody => 'Seuls ses membres peuvent lire ce thread.';

  @override
  String get errorQuarantinedTitle => 'Subreddit en quarantaine';

  @override
  String get errorQuarantinedBody =>
      'Reddit restreint l\'accès à ce subreddit.';

  @override
  String get errorBannedTitle => 'Subreddit banni';

  @override
  String get errorBannedBody => 'Ce subreddit n\'existe plus sur Reddit.';

  @override
  String get errorDeletedTitle => 'Ce post a été supprimé';

  @override
  String get errorDeletedBody => 'Il n\'y a plus rien à résumer.';

  @override
  String get errorNotFoundTitle => 'Thread introuvable';

  @override
  String get errorNotFoundBody =>
      'Reddit ne trouve pas ce post. Vérifie le lien.';

  @override
  String get errorUnsupportedUrlTitle => 'Ce lien n\'est pas un thread';

  @override
  String get errorUnsupportedUrlBody =>
      'TL;DR+ résume les posts Reddit, pas les profils ni les subreddits.';

  @override
  String get errorInvalidUrlTitle => 'Ce lien n\'est pas un thread Reddit';

  @override
  String get errorInvalidUrlBody =>
      'Partage ou colle un lien vers un post Reddit.';

  @override
  String get errorEmptyTitle => 'Rien à résumer';

  @override
  String get errorEmptyBody =>
      'Ce post n\'a ni texte ni commentaires exploitables.';

  @override
  String errorKeyInvalidTitle(String provider) {
    return 'Ta clé $provider est refusée';
  }

  @override
  String get errorKeyInvalidBody =>
      'Vérifie ou remplace ta clé dans les réglages.';

  @override
  String errorKeyMissingTitle(String provider) {
    return 'Aucune clé $provider';
  }

  @override
  String get errorKeyMissingBody => 'Ajoute ta clé IA pour lancer un résumé.';

  @override
  String get errorModelUnavailableTitle => 'Modèle indisponible';

  @override
  String get errorModelUnavailableBody =>
      'Choisis un autre modèle dans les réglages.';

  @override
  String get errorTimeoutTitle => 'C\'est trop long';

  @override
  String get errorTimeoutBody =>
      'Le résumé n\'a pas abouti à temps. Réessaie dans un moment.';

  @override
  String get errorNetworkTitle => 'Pas de connexion';

  @override
  String get errorNetworkBody => 'Vérifie ta connexion internet puis réessaie.';

  @override
  String errorLlmUnavailableTitle(String provider) {
    return '$provider ne répond pas';
  }

  @override
  String get errorLlmUnavailableBody =>
      'Le fournisseur IA est indisponible pour le moment.';

  @override
  String get errorOutputInvalidTitle => 'Réponse de l\'IA inutilisable';

  @override
  String get errorOutputInvalidBody =>
      'L\'IA a renvoyé un résultat incomplet. Réessaie.';

  @override
  String get errorRedditBlockedTitle => 'Reddit refuse l\'accès';

  @override
  String get errorRedditBlockedBody =>
      'Reddit bloque temporairement la lecture de ce thread. Réessaie dans quelques minutes.';

  @override
  String get errorRedditUnavailableTitle => 'Reddit ne répond pas';

  @override
  String get errorRedditUnavailableBody =>
      'Reddit est indisponible pour le moment. Réessaie.';

  @override
  String get errorGenericTitle => 'Une erreur est survenue';

  @override
  String get errorGenericBody => 'Réessaie dans un moment.';

  @override
  String get emotionJoy => 'joie';

  @override
  String get emotionSadness => 'tristesse';

  @override
  String get emotionAnger => 'colère';

  @override
  String get emotionFear => 'peur';

  @override
  String get emotionDisgust => 'dégoût';

  @override
  String get emotionSurprise => 'surprise';

  @override
  String get emotionLove => 'amour';

  @override
  String get emotionPride => 'fierté';

  @override
  String get emotionRelief => 'soulagement';

  @override
  String get emotionHope => 'espoir';

  @override
  String get emotionExcitement => 'enthousiasme';

  @override
  String get emotionEnvy => 'envie';

  @override
  String get emotionGuilt => 'culpabilité';

  @override
  String get emotionShame => 'honte';

  @override
  String get emotionNeutral => 'neutre';

  @override
  String get sentimentPositive => 'Positif';

  @override
  String get sentimentNegative => 'Négatif';

  @override
  String get sentimentNeutral => 'Neutre';

  @override
  String get toxicityLow => 'Toxicité faible';

  @override
  String get toxicityModerate => 'Toxicité modérée';

  @override
  String get toxicityHigh => 'Toxicité élevée';

  @override
  String get toxicityUnknown => 'Toxicité —';

  @override
  String get relativeJustNow => 'à l\'instant';

  @override
  String relativeMinutes(String count) {
    return 'il y a $count min';
  }

  @override
  String relativeHours(String count) {
    return 'il y a $count h';
  }

  @override
  String get relativeYesterday => 'hier';

  @override
  String relativeDays(String count) {
    return 'il y a $count jours';
  }

  @override
  String get dateShortPattern => 'd MMM';

  @override
  String get dateLongPattern => 'd MMM y';

  @override
  String percentValue(String value) {
    return '$value %';
  }

  @override
  String get commonAdultContent => 'Contenu adulte';

  @override
  String get appNotAThread => 'Ce lien n\'est pas un thread Reddit';

  @override
  String get appSummaryReady => 'Résumé prêt';

  @override
  String get appView => 'Voir';

  @override
  String get appSummaryFailed => 'Le résumé a échoué';

  @override
  String get appDetails => 'Détails';

  @override
  String get homeNotAThread => 'Ce lien n\'est pas un thread Reddit';

  @override
  String get homeClipboardEmpty => 'Le presse-papiers est vide';

  @override
  String get homeSummaryDeleted => 'Résumé supprimé';

  @override
  String get homeUndo => 'Annuler';

  @override
  String get homeShare => 'Partager';

  @override
  String get homeDelete => 'Supprimer';

  @override
  String get homeSettings => 'Réglages';

  @override
  String get homeRecent => 'Récents';

  @override
  String get homePasteLink => 'Coller un lien';

  @override
  String get homeUrlHint => 'Coller un lien Reddit';

  @override
  String get homeSummarize => 'Résumer';

  @override
  String get homeAddKey => 'Ajoute ta clé IA pour commencer';

  @override
  String homeSentiment(String sentiment) {
    return 'Sentiment $sentiment';
  }

  @override
  String get homeEmptyTitle => 'Résume un thread en 3 gestes';

  @override
  String get homeEmptyStep1 => 'Dans Reddit, ouvre un post';

  @override
  String get homeEmptyStep2 => 'Touche Partager';

  @override
  String get homeEmptyStep3 => 'Choisis TL;DR+';

  @override
  String get homeEmptyIosHint =>
      'Pas dans la liste ? Touche « Plus » et active TL;DR+.';

  @override
  String get homeSeeExample => 'Voir un exemple';

  @override
  String settingsModelFallback(String from, String to) {
    return 'Modèle $from indisponible, $to utilisé.';
  }

  @override
  String get settingsClearTitle => 'Effacer l\'historique ?';

  @override
  String get settingsClearBody =>
      'Tous les résumés enregistrés sur ce téléphone seront supprimés.';

  @override
  String get settingsCancel => 'Annuler';

  @override
  String get settingsClear => 'Effacer';

  @override
  String get settingsCleared => 'Historique effacé';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsProvider => 'Fournisseur IA';

  @override
  String get settingsModel => 'Modèle';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsDeviceLanguage => 'Langue de l\'appareil';

  @override
  String get settingsClearHistory => 'Effacer l\'historique';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get keyFormPrivacy =>
      'Ta clé est enregistrée uniquement sur ce téléphone et n\'est envoyée qu\'à ton fournisseur IA.';

  @override
  String get keyFormSave => 'Enregistrer';

  @override
  String keyFormDeleteTitle(String provider) {
    return 'Supprimer la clé $provider ?';
  }

  @override
  String get keyFormCancel => 'Annuler';

  @override
  String get keyFormDelete => 'Supprimer';

  @override
  String get keyFormValid => '✓ Clé valide';

  @override
  String keyFormRefused(String provider) {
    return '✗ Clé refusée par $provider';
  }

  @override
  String get keyFormUnverified => 'Enregistrée, non vérifiée';

  @override
  String get keyFormEmpty => 'Colle ta clé avant d\'enregistrer';

  @override
  String keyFormLabel(String provider) {
    return 'Clé API $provider';
  }

  @override
  String get keyFormHint => 'Colle ta clé ici';

  @override
  String get keyFormShow => 'Afficher la clé';

  @override
  String get keyFormHide => 'Masquer la clé';

  @override
  String get keyFormDeleteKey => 'Supprimer la clé';

  @override
  String keyFormPatternMismatch(String provider) {
    return 'Ce format ne ressemble pas à une clé $provider.';
  }

  @override
  String keyFormGetKey(String provider) {
    return 'Obtenir une clé $provider';
  }

  @override
  String get setupGeminiSubtitle => 'Offre gratuite disponible';

  @override
  String get setupAnthropicSubtitle => 'Claude, par Anthropic';

  @override
  String get setupOpenaiSubtitle => 'GPT, par OpenAI';

  @override
  String get setupStep1 => 'Étape 1 sur 2';

  @override
  String get setupPitch =>
      'Résume n\'importe quel thread Reddit avec ta propre IA.';

  @override
  String get setupChooseProvider => 'Choisis ton fournisseur';

  @override
  String get setupContinue => 'Continuer';

  @override
  String get setupStep2 => 'Étape 2 sur 2';

  @override
  String setupPasteKey(String provider) {
    return 'Colle ta clé $provider';
  }

  @override
  String get setupVerify => 'Vérifier';

  @override
  String get setupDone => 'C\'est prêt ✓';

  @override
  String summaryVerdictSemantics(
    String sentiment,
    String emotions,
    String toxicity,
  ) {
    return 'Sentiment $sentiment. Émotions : $emotions. $toxicity.';
  }

  @override
  String get summaryReadLess => 'Lire moins';

  @override
  String get summaryReadMore => 'Lire plus';

  @override
  String get summaryFetchingStep => 'Récupération du thread…';

  @override
  String get summaryAnalyzingStep => 'Analyse par l\'IA…';

  @override
  String get summaryInProgress => 'Résumé en cours';

  @override
  String get summaryRedditThread => 'Thread Reddit';

  @override
  String get summaryLongWait =>
      'Les longs threads peuvent prendre jusqu\'à 30 s.';

  @override
  String get summaryCancel => 'Annuler';

  @override
  String get summaryOpenSettings => 'Ouvrir les réglages';

  @override
  String summaryRetryIn(String time) {
    return 'Réessayer dans $time';
  }

  @override
  String get summaryRetry => 'Réessayer';

  @override
  String get summaryBackHome => 'Retour à l\'accueil';

  @override
  String get summaryModelFallback =>
      'Modèle indisponible : le modèle par défaut a été utilisé.';

  @override
  String get summaryRegenerateTitle => 'Régénérer ce résumé ?';

  @override
  String get summaryRegenerateBody => 'La traduction française sera supprimée.';

  @override
  String get summaryRegenerate => 'Régénérer';

  @override
  String get summaryCannotOpenReddit => 'Impossible d\'ouvrir Reddit';

  @override
  String get summaryShare => 'Partager le résumé';

  @override
  String get summaryOpenInReddit => 'Ouvrir dans Reddit';

  @override
  String get summaryMoreOptions => 'Plus d\'options';

  @override
  String get summaryAnalyzingSemantics => 'Analyse par l\'IA en cours';

  @override
  String get summaryFetchingSemantics => 'Récupération du thread';

  @override
  String get summaryDemoBanner =>
      'Exemple : ce résumé n\'utilise pas ta clé et n\'est pas enregistré.';

  @override
  String get summaryClose => 'Fermer';

  @override
  String summaryAlreadySummarized(String date) {
    return 'Déjà résumé $date';
  }

  @override
  String summaryBannerOnDate(String date) {
    return 'le $date';
  }

  @override
  String get summaryInShort => 'En bref';

  @override
  String get summaryViewpoints => 'Points de vue';

  @override
  String summaryStats(String score, String percent, String comments) {
    return '$score points · $percent upvotés · $comments commentaires';
  }

  @override
  String summaryCommentsAnalyzed(String analyzed, String total, String model) {
    return '$analyzed commentaires analysés sur $total · $model';
  }

  @override
  String get summaryAiTake => 'L\'avis de l\'IA';

  @override
  String get summaryTranslateToFrench => 'Traduire en français';

  @override
  String summaryOriginal(String code) {
    return 'VO ($code)';
  }

  @override
  String get summaryFrench => 'FR';
}
