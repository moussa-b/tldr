# Changelog

Toutes les versions notables de TL;DR+. La version de l'app (`pubspec.yaml`) suit les trois premiers chiffres de `VERSION`.

## [1.0.0.0] - 2026-10-09

Première version publique de TL;DR+, sur Android et iOS.

### Added
- Partage un post depuis l'app Reddit (Android et iOS) : TL;DR+ s'ouvre directement sur son résumé.
- Le post Reddit s'affiche le temps de sa lecture, puis se dissout en poussière pendant que l'IA écrit et laisse place au résumé.
- Résumé court, résumé détaillé, sentiment, émotions, toxicité et avis de l'IA pour chaque thread, à partir des commentaires les plus pertinents.
- Ta propre clé IA au choix : Gemini, Claude (Anthropic) ou OpenAI. La clé est vérifiée à l'enregistrement quand le réseau répond, stockée dans le Keychain ou le Keystore, et n'est envoyée qu'au fournisseur choisi.
- Historique local des résumés, avec suppression annulable, partage, et détection d'un thread déjà résumé.
- Traduction du résumé en français, et régénération avec le fournisseur et le modèle choisis dans les réglages.
- Un exemple de résumé à consulter sans clé ni réseau pour découvrir l'app.
- Messages d'erreur clairs (thread supprimé ou privé, clé refusée, quota épuisé, Reddit indisponible) avec l'action qui débloque.
- Design « Céladon » (Plex Sans, Literata), lisible jusqu'à 200 % de taille de texte, et une icône d'app dédiée sur iOS et Android.
