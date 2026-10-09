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

Le projet est épinglé sur **Flutter 3.47.5 via FVM** (`.fvmrc`) : préfixe les commandes par `fvm`. Le Flutter global de la machine n'est pas utilisé. Les plugins iOS passent par Swift Package Manager (pas de CocoaPods).

```bash
cp config/example.json config/dev.json   # puis remplir REDDIT_CLIENT_ID
fvm flutter run --dart-define-from-file=config/dev.json
```

Pour développer sans réseau ni clé, avec des réponses simulées :

```bash
fvm flutter run --dart-define=API_MODE=mock
```

### Sur ton téléphone Android branché en USB (Huawei ANE-LX1)

```bash
fvm flutter run -d 9WV7N19422001815 --dart-define=API_MODE=mock
```

- `9WV7N19422001815` est l'identifiant du téléphone ; `fvm flutter devices` liste les appareils branchés.
- Sur Huawei, valide la fenêtre « Installer via USB » sur l'écran du téléphone, sinon l'installation reste bloquée.
- Dans le terminal : `r` recharge après une modification, `R` redémarre, `q` quitte. Les lignes `ZeroHung` sont du bruit système Huawei.
- Pour le mode réel (une fois `config/dev.json` rempli) : `fvm flutter run -d 9WV7N19422001815 --dart-define-from-file=config/dev.json`.

### Mode mock

Le mock ne lit pas Reddit : le **texte du résumé est toujours l'un de 3 exemples** (AskReddit, r/france, r/technology), choisi selon l'URL. Le lien « Ouvrir dans Reddit » et l'historique pointent en revanche vers le thread réellement partagé.

N'importe quelle clé fonctionne. Ces entrées déclenchent les erreurs :

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
fvm flutter analyze
fvm flutter test
```

## État d'avancement (2026-10-09)

| Élément | État |
|---|---|
| Moteur sur l'appareil (Reddit, sélection R9, prompts, Gemini / OpenAI / Anthropic en REST, deadline 90 s + retry R1) | ✅ Codé et testé unitairement. **Jamais exécuté contre les vraies API IA** : il faut des clés. |
| Écrans Accueil, Résumé, Réglages, Setup, démo, erreurs, traduction, régénération, doublons, reprise | ✅ |
| Historique SQLite, clés sécurisées, catalogue embarqué (`assets/catalog.json`) | ✅ |
| Partage Android (intent `SEND text/plain`) | ✅ L'APK debug compile (AGP 9.2.1, Gradle 9.4.1, compileSdk 37). |
| Partage iOS (Share Extension liée au paquet SPM `receive-sharing-intent`, App Group `group.com.bdzapps.tldr`, cycle de vie UIScene) | ✅ L'app compile pour le simulateur, extension embarquée. Sur iPhone réel : choisir ton équipe de signature et activer l'App Group dans Xcode sur les deux cibles. `receive_sharing_intent` est épinglé en 1.9.0 parce que l'extension le référence par son chemin versionné : en cas de montée de version, mettre à jour ce chemin dans le projet Xcode. |
| Polices Plex Sans + Literata | ⚠️ Téléchargées par `google_fonts` au premier lancement. `tool/fetch_fonts.sh` permet de les embarquer. |
| Identifiants de modèles (`assets/catalog.json`) | ⚠️ À vérifier dans la documentation de chaque fournisseur. |
| Tests | 69 tests : unitaires, moteur, widgets, accessibilité, texte à 200 % |
