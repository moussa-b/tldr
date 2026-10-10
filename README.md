# TL;DR+

App mobile Flutter (Android + iOS) qui résume un thread Reddit avec **ta propre clé IA** (Gemini, Claude ou OpenAI). On partage un post depuis l'app Reddit vers TL;DR+, le résumé s'affiche et reste dans un historique local.

- Spec : [docs/spec/tldr-plus-spec.md](docs/spec/tldr-plus-spec.md)
- Design system : [DESIGN.md](DESIGN.md) (« Céladon »)

## Architecture

Tout tourne sur l'appareil : il n'y a ni serveur ni mode simulé.

```
UI (lib/features)  ──▶  SummaryService  ──▶  TldrApi ──▶ DirectTldrApi (lib/data/engine)
                         │  (historique,                  ├─ lecture du thread Reddit
                         │   réglages, clés)              ├─ sélection des commentaires
                         ▼                                └─ appel REST au fournisseur IA de l'utilisateur
                   SQLite + Keychain/Keystore
```

- Les clés IA sont stockées uniquement dans le stockage sécurisé du téléphone et ne sont envoyées qu'au fournisseur choisi.
- `TldrApi` n'a qu'une implémentation dans l'app. Les tests la remplacent par `FakeTldrApi` (`test/fake_tldr_api.dart`, fixtures dans `test/fixtures/`).
- « Voir un exemple » affiche un résumé figé (`assets/demo/summary_fr.json`), sans clé ni réseau.

### Lecture de Reddit

Reddit renvoie **403** aux requêtes `.json` anonymes d'un client HTTP. Deux modes existent :

- **Par défaut, sans identifiant Reddit** : l'écran Résumé affiche le post dans une WebView (`lib/data/engine/reddit_page.dart`). La WebView passe le contrôle JavaScript de Reddit comme un navigateur, puis l'app lit `/comments/<id>.json` depuis cette page. Une fois le thread lu, la page se dissout en poussière pendant que l'IA écrit (`lib/features/summary/dust_veil.dart`). La bannière cookies de Reddit est masquée, rien n'est accepté. ⚠️ Cet accès n'est pas approuvé par la [Responsible Builder Policy](https://support.reddithelp.com/hc/en-us/articles/42728983564564-Responsible-Builder-Policy) de Reddit.
- **Avec `REDDIT_CLIENT_ID`** (app Reddit de type *installed app*, à demander à Reddit via le ticket développeur de la policy) : l'app passe par l'API OAuth officielle, sans WebView.

## Lancer l'app

Le projet est épinglé sur **Flutter 3.47.5 via FVM** (`.fvmrc`) : préfixe les commandes par `fvm`. Le Flutter global de la machine n'est pas utilisé. Les plugins iOS passent par Swift Package Manager (pas de CocoaPods).

```bash
fvm flutter run --dart-define-from-file=config/example.json
```

Au premier lancement, l'app demande une clé IA (Gemini a une offre gratuite : https://aistudio.google.com/apikey).

Pour utiliser un identifiant Reddit approuvé : copie `config/example.json` en `config/dev.json`, remplis `REDDIT_CLIENT_ID` et ton pseudo dans `REDDIT_USER_AGENT`, puis lance avec `--dart-define-from-file=config/dev.json`. `dart run tool/smoke_reddit.dart <url>` vérifie alors l'accès OAuth (variable d'environnement `REDDIT_CLIENT_ID`).

### Sur ton téléphone Android branché en USB (Huawei ANE-LX1)

```bash
fvm flutter run -d 9WV7N19422001815 --dart-define-from-file=config/example.json
```

- `9WV7N19422001815` est l'identifiant du téléphone ; `fvm flutter devices` liste les appareils branchés.
- Sur Huawei, valide la fenêtre « Installer via USB » sur l'écran du téléphone, sinon l'installation reste bloquée.
- Dans le terminal : `r` recharge après une modification, `R` redémarre, `q` quitte. Les lignes `ZeroHung` sont du bruit système Huawei.

## Tests

```bash
fvm flutter analyze
fvm flutter test
```

## État d'avancement (2026-10-10)

| Élément | État |
|---|---|
| Moteur sur l'appareil (Reddit, sélection R9, prompts, Gemini / OpenAI / Anthropic en REST, deadline 90 s + retry R1) | ✅ Codé et testé unitairement, lancé avec une vraie clé sur émulateur Android le 2026-10-10. |
| Lecture de Reddit par WebView + transition « poussière » | ✅ Vérifiée sur simulateur iOS et émulateur Android le 2026-10-10. |
| Écrans Accueil, Résumé, Réglages, Setup, exemple, erreurs, traduction, régénération, doublons, reprise | ✅ |
| Historique SQLite, clés sécurisées, catalogue embarqué (`assets/catalog.json`) | ✅ |
| Partage Android (intent `SEND text/plain`) | ✅ L'APK debug compile (AGP 9.2.1, Gradle 9.4.1, compileSdk 37). |
| Partage iOS (Share Extension liée au paquet SPM `receive-sharing-intent`, App Group `group.com.bdzapps.tldr`, cycle de vie UIScene) | ✅ L'app compile pour le simulateur, extension embarquée. Sur iPhone réel : choisir ton équipe de signature et activer l'App Group dans Xcode sur les deux cibles. `receive_sharing_intent` est épinglé en 1.9.0 parce que l'extension le référence par son chemin versionné : en cas de montée de version, mettre à jour ce chemin dans le projet Xcode. |
| Polices Plex Sans + Literata | ⚠️ Téléchargées par `google_fonts` au premier lancement. `tool/fetch_fonts.sh` permet de les embarquer. |
| Identifiants de modèles (`assets/catalog.json`) | ⚠️ À vérifier dans la documentation de chaque fournisseur. |
| Tests | 70 tests : unitaires, moteur, widgets, accessibilité, texte à 200 %, transition poussière |
