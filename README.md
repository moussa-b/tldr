# TL;DR+

App mobile Flutter (Android + iOS) qui résume un thread Reddit avec **ta propre clé IA** (Gemini, Claude ou OpenAI). On partage un post depuis l'app Reddit vers TL;DR+, le résumé s'affiche et reste dans un historique local.

- Spec : [docs/spec/tldr-plus-spec.md](docs/spec/tldr-plus-spec.md) (lire d'abord la section « Révision d'architecture (2026-10-09) »)
- Design system : [DESIGN.md](DESIGN.md) (« Céladon »)

## Architecture

Tout tourne sur l'appareil, sans backend.

```
UI (lib/features)  ──▶  SummaryService  ──▶  TldrApi  ◀── le seul point de bascule
                         │  (historique,       ├─ DirectTldrApi   (API_MODE=direct, défaut)
                         │   réglages, clés)   │    Reddit + sélection des commentaires + IA (lib/data/engine)
                         ▼                     ├─ MockTldrApi     (API_MODE=mock, fixtures)
                   SQLite + Keychain/Keystore  └─ BackendTldrApi  (à écrire si un jour on ajoute un serveur)
```

- Les clés IA sont stockées uniquement dans le stockage sécurisé du téléphone et ne sont envoyées qu'au fournisseur choisi.
- Pour passer un jour à un backend, il suffit d'implémenter `TldrApi` en HTTP et de le brancher dans `lib/app/providers.dart` (`apiProvider`). L'ancien contrat OpenAPI se trouve dans l'historique git (`docs/api/openapi.yaml`, commit `c006290`).

## Lancer l'app

```bash
cp config/example.json config/dev.json   # puis remplir REDDIT_CLIENT_ID
flutter run --dart-define-from-file=config/dev.json
```

Pour développer sans réseau ni clé, avec des réponses simulées :

```bash
flutter run --dart-define=API_MODE=mock
```

En mode mock, n'importe quelle clé fonctionne. Ces entrées déclenchent les erreurs :

| Entrée | Erreur |
|---|---|
| URL contenant `notfound` | thread introuvable |
| URL contenant `deleted` | post supprimé |
| URL avec `/user/` ou `/wiki/` | lien non supporté |
| URL contenant `ratelimit` | trop de demandes (compte à rebours de 2 min) |
| URL contenant `timeout` | délai dépassé |
| clé `invalid` | clé refusée |
| clé `quota` | quota épuisé |

## ⚠️ Accès à Reddit : un identifiant d'app est nécessaire

Reddit renvoie **403** sur les endpoints `.json` anonymes. Je l'ai vérifié le 2026-10-09 avec `tool/smoke_reddit.dart`, quel que soit le User-Agent. Le mode direct a donc besoin d'une app Reddit de type **installed app** (sans secret) :

1. Va sur https://www.reddit.com/prefs/apps et clique sur « create another app… ».
2. Choisis le type **installed app** et une redirect URI quelconque (par exemple `http://localhost`). Reddit peut désormais demander une validation avant d'accorder l'accès à l'API.
3. Copie le `client_id`, affiché sous le nom de l'app, dans `REDDIT_CLIENT_ID` de `config/dev.json`. Mets aussi ton nom d'utilisateur Reddit dans `REDDIT_USER_AGENT`.
4. Vérifie la connexion :

```bash
dart run tool/smoke_reddit.dart https://www.reddit.com/r/france/comments/<id>/
```

Sans identifiant, l'app affiche « Reddit refuse l'accès » au lieu d'un résumé.

## Tests

```bash
flutter analyze
flutter test
```

## État d'avancement (2026-10-09)

| Élément | État |
|---|---|
| Moteur sur l'appareil (Reddit, sélection R9, prompts, Gemini / OpenAI / Anthropic en REST, deadline 90 s + retry R1) | ✅ Codé et testé unitairement. **Jamais exécuté contre les vraies API IA** : il faut des clés. |
| Écrans Accueil, Résumé, Réglages, Setup, démo, erreurs, traduction, régénération, doublons, reprise | ✅ |
| Historique SQLite, clés sécurisées, catalogue embarqué (`assets/catalog.json`) | ✅ |
| Partage Android (intent `SEND text/plain`) | ✅ L'APK debug compile. |
| Partage iOS (cible Share Extension, App Group `group.com.bdzapps.tldr`) | ⚠️ Configuré mais **pas encore compilé** : Flutter 3.32.8 ne fonctionne pas avec Xcode 27 (`debug_unpack_ios` interprète mal la sortie de `lipo`). Correctif : `flutter upgrade`. Sur iPhone réel, il faudra aussi choisir ton équipe de signature et activer l'App Group dans Xcode, sur les deux cibles. |
| Polices Plex Sans + Literata | ⚠️ Téléchargées par `google_fonts` au premier lancement. `tool/fetch_fonts.sh` permet de les embarquer. |
| Identifiants de modèles (`assets/catalog.json`) | ⚠️ À vérifier dans la documentation de chaque fournisseur. |
| Tests | 69 tests : unitaires, moteur, widgets, accessibilité, texte à 200 % |
