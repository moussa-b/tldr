/// Error surfaced by [TldrApi]. `code` is one of the contract error codes
/// (docs/api/openapi.yaml `ErrorCode`) or a client-only code
/// (`NETWORK_ERROR`, `TIMEOUT`, `CANCELLED`).
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

  /// `details.reason` (THREAD_UNAVAILABLE, VALIDATION_ERROR).
  final String? reason;

  factory ApiError.fromBody(Map<String, dynamic> body, {int? retryAfterHeader}) {
    final error = body['error'] as Map<String, dynamic>;
    final details = error['details'] as Map<String, dynamic>?;
    return ApiError(
      code: error['code'] as String,
      message: error['message'] as String,
      retryable: error['retryable'] as bool,
      retryAfterSeconds:
          (details?['retryAfterSeconds'] as num?)?.toInt() ?? retryAfterHeader,
      reason: details?['reason'] as String?,
    );
  }

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

  bool get hasCountdown => code == 'RATE_LIMITED' || code == 'LLM_QUOTA_EXCEEDED';

  @override
  String toString() => 'ApiError($code: $message)';
}

/// French copy shown to the user for one error (spec D-7).
class ErrorCopy {
  const ErrorCopy(this.title, this.body);

  final String title;
  final String body;
}

ErrorCopy errorCopy(ApiError error, {String providerLabel = 'le fournisseur'}) {
  switch (error.code) {
    case 'RATE_LIMITED':
      return const ErrorCopy('Trop de demandes',
          'Tu as lancé beaucoup de résumés en peu de temps. Patiente un instant.');
    case 'LLM_QUOTA_EXCEEDED':
      return ErrorCopy('Quota du fournisseur atteint',
          'Ton quota $providerLabel est épuisé pour le moment.');
    case 'THREAD_UNAVAILABLE':
      return switch (error.reason) {
        'removed' => const ErrorCopy('Post retiré par la modération',
            'Ce thread n\'est plus disponible sur Reddit.'),
        'private' => const ErrorCopy('Ce subreddit est privé',
            'Seuls ses membres peuvent lire ce thread.'),
        'quarantined' => const ErrorCopy('Subreddit en quarantaine',
            'Reddit restreint l\'accès à ce subreddit.'),
        'banned' => const ErrorCopy('Subreddit banni',
            'Ce subreddit n\'existe plus sur Reddit.'),
        _ => const ErrorCopy(
            'Ce post a été supprimé', 'Il n\'y a plus rien à résumer.'),
      };
    case 'THREAD_NOT_FOUND':
      return const ErrorCopy('Thread introuvable',
          'Reddit ne trouve pas ce post. Vérifie le lien.');
    case 'UNSUPPORTED_URL':
      return const ErrorCopy('Ce lien n\'est pas un thread',
          'TL;DR+ résume les posts Reddit, pas les profils ni les subreddits.');
    case 'INVALID_URL':
      return const ErrorCopy('Ce lien n\'est pas un thread Reddit',
          'Partage ou colle un lien vers un post Reddit.');
    case 'THREAD_EMPTY':
      return const ErrorCopy('Rien à résumer',
          'Ce post n\'a ni texte ni commentaires exploitables.');
    case 'LLM_KEY_INVALID':
      return ErrorCopy('Ta clé $providerLabel est refusée',
          'Vérifie ou remplace ta clé dans les réglages.');
    case 'LLM_KEY_MISSING':
      return ErrorCopy('Aucune clé $providerLabel',
          'Ajoute ta clé IA pour lancer un résumé.');
    case 'LLM_MODEL_UNAVAILABLE':
    case 'UNSUPPORTED_MODEL':
      return const ErrorCopy('Modèle indisponible',
          'Choisis un autre modèle dans les réglages.');
    case 'TIMEOUT':
      return const ErrorCopy('C\'est trop long',
          'Le résumé n\'a pas abouti à temps. Réessaie dans un moment.');
    case 'NETWORK_ERROR':
      return const ErrorCopy('Pas de connexion',
          'Vérifie ta connexion internet puis réessaie.');
    case 'LLM_UNAVAILABLE':
      return ErrorCopy('$providerLabel ne répond pas',
          'Le fournisseur IA est indisponible pour le moment.');
    case 'LLM_OUTPUT_INVALID':
      return const ErrorCopy('Réponse de l\'IA inutilisable',
          'L\'IA a renvoyé un résultat incomplet. Réessaie.');
    case 'REDDIT_UNAVAILABLE':
      return const ErrorCopy('Reddit ne répond pas',
          'Reddit est indisponible pour le moment. Réessaie.');
    case 'APP_KEY_INVALID':
      return const ErrorCopy('Version de l\'app refusée',
          'Mets TL;DR+ à jour pour continuer.');
    default:
      return const ErrorCopy('Une erreur est survenue', 'Réessaie dans un moment.');
  }
}
