# TL;DR+ en français et en anglais

Statut : validé le 2026-10-22, prêt à implémenter. Version cible : 1.1.0.

## Context

TL;DR+ a été écrit pour un usage personnel, donc entièrement en français. L'app va être présentée sur Reddit, où la majorité des utilisateurs ont un téléphone en anglais : aujourd'hui ils tombent sur une interface qu'ils ne lisent pas, et un bouton « Traduire en français » qui n'a pas de sens pour eux. Il faut une interface en anglais et en français, choisie d'après la langue de l'appareil et modifiable dans les réglages, avec une structure qui permet d'ajouter une langue sans toucher au code des écrans.

## Current State

Vérifié sur `develop` (`b4564ba`, version 1.0.2) le 2026-10-22.

- Aucune couche de localisation : pas de `flutter_localizations`, pas de `supportedLocales`, pas de fichier `.arb`. `MaterialApp.router` ([lib/app/app.dart:105](../../lib/app/app.dart)) n'a ni `locale` ni `localizationsDelegates`.
- Les textes sont des littéraux français dans le code. Inventaire (lignes contenant du texte affiché) :

| Fichier | Lignes de texte | Nature |
|---|---|---|
| `lib/core/errors.dart` | 42 | `errorCopy()` : titre + corps de chaque erreur, `providerLabel` par défaut `'le fournisseur'` |
| `lib/features/summary/summary_screen.dart` | 32 | écran résumé, chargement, actions, `_LanguageControl` (« Traduire en français », `VO (EN) \| FR`, « Réessayer ») |
| `lib/features/home/home_screen.dart` | 20 | accueil, historique, bannière clé, texte partagé |
| `lib/features/settings/key_form.dart` | 15 | saisie et vérification de la clé |
| `lib/core/labels.dart` | 15 | émotions (15), sentiments (3), toxicité (4), `relativeDate()`, `compactNumber()` |
| `lib/features/summary/summary_widgets.dart` | 14 | blocs du résumé |
| `lib/features/setup/setup_screen.dart` | 11 | configuration du fournisseur |
| `lib/features/settings/settings_screen.dart` | 11 | réglages, `'Version 1.0.0'` codé en dur (faux : 1.0.2) |
| `lib/app/app.dart` | 4 | snackbars « Résumé prêt », « Le résumé a échoué », « Détails », lien invalide |
| `lib/core/widgets/common.dart` | 1 | libellé d'accessibilité « Contenu adulte » |

- Dates et nombres figés sur le français : `initializeDateFormatting('fr_FR')` ([lib/main.dart:19](../../lib/main.dart)), `DateFormat(..., 'fr_FR')` ([lib/core/labels.dart:75](../../lib/core/labels.dart)), `NumberFormat.compact(locale: 'fr_FR')` ([lib/core/labels.dart:78](../../lib/core/labels.dart)).
- Traduction des résumés codée « français » : `SummaryEntry.displayed` et `canTranslate` ([lib/data/db/summaries_dao.dart:61-64](../../lib/data/db/summaries_dao.dart)), colonne `analysis_fr_json`, `display_lang` (`'orig' | 'fr'`), `translate(..., targetLanguage = 'fr')`. `displayed` sert aussi au texte partagé depuis l'accueil ([lib/features/home/home_screen.dart:137](../../lib/features/home/home_screen.dart)).
- Contenus embarqués en français : `assets/demo/summary_fr.json` (« Voir un exemple »), le nom `Gemini Pro (dernière version)` dans `assets/catalog.json`.
- Réglages stockés dans la table `settings` ([lib/data/settings/settings_repository.dart](../../lib/data/settings/settings_repository.dart)) : fournisseur, modèle, catalogue, résumé en attente. Aucune langue.
- Plateformes : `ios/Runner/Info.plist` sans `CFBundleLocalizations` ; Android sans `locales_config.xml`. L'extension de partage iOS (`ios/Share Extension`) n'affiche aucun texte.
- Tests qui vérifient du texte français : `test/widget/app_test.dart` (20 lignes), `test/core/labels_test.dart` (1), `test/data/service_test.dart` (2).

## Proposed Change

L'interface existe en français et en anglais. La langue vient du réglage « Langue » : « Langue de l'appareil » (par défaut), « Français » ou « English ». En mode appareil, un appareil en français (toute variante `fr_*`) donne le français ; toute autre langue donne l'anglais.

Le résumé reste écrit dans la langue du thread, comme aujourd'hui : seule l'interface change.

En français, rien ne change par rapport à la 1.0.2. En anglais, la traduction des résumés n'apparaît pas : ni le bouton « Traduire en français », ni le sélecteur `VO | FR`, et le résumé affiché est toujours l'original. Une traduction française déjà enregistrée reste en base et réapparaît si l'app repasse en français.

### Implementation Details

**1. Textes : `gen-l10n` (outil officiel Flutter, Flutter 3.47.5).**

- `pubspec.yaml` : ajouter `flutter_localizations: { sdk: flutter }` dans `dependencies`, et `generate: true` sous `flutter:`.
- `l10n.yaml` à la racine :

```yaml
arb-dir: lib/l10n
output-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
nullable-getter: false
untranslated-messages-file: build/untranslated_messages.json
```

- Pas de clé `synthetic-package` : le paquet synthétique `flutter_gen` n'existe plus depuis Flutter 3.32, et `gen-l10n` écrit dans `output-dir`. Import dans l'app : `import 'package:tldr/l10n/app_localizations.dart';`.
- `lib/l10n/app_en.arb` (modèle, avec une `@description` par clé) et `lib/l10n/app_fr.arb`. Les fichiers générés (`app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_fr.dart`) sont produits dans `lib/l10n/` par `fvm flutter gen-l10n` (et à chaque `flutter run`/`build`) et commités.
- Clés en `camelCase`, préfixées par l'écran ou le domaine : `settingsTitle`, `summaryTranslateToFrench`, `errorThreadNotFoundTitle`, `errorThreadNotFoundBody`, `emotionJoy`, `toxicityLow`… Les textes avec paramètres utilisent les placeholders ARB (`errorKeyInvalidTitle` : `"Your {provider} key was refused"`), les pluriels utilisent ICU.
- `relativeDate` garde exactement sa logique actuelle ([lib/core/labels.dart:56-76](../../lib/core/labels.dart)) ; seuls les textes changent, une clé par branche :

| Branche actuelle | Clé ARB | fr (inchangé) | en |
|---|---|---|---|
| `< 1 min` | `relativeJustNow` | `à l'instant` | `just now` |
| `< 60 min` | `relativeMinutes(count)` | `il y a {count} min` | `{count} min ago` |
| `< 24 h`, même jour | `relativeHours(count)` | `il y a {count} h` | `{count} h ago` |
| la veille | `relativeYesterday` | `hier` | `yesterday` |
| 2 à 6 jours (calendaires, `clamp(2, 6)`) | `relativeDays(count)` | `il y a {count} jours` | `{count} days ago` |
| ≥ 7 jours, même année | `DateFormat(l.dateShortPattern, localeName)` | motif `d MMM` → `3 oct.` | motif `MMM d` → `Oct 3` |
| ≥ 7 jours, autre année | `DateFormat(l.dateLongPattern, localeName)` | motif `d MMM y` → `3 oct. 2025` | motif `MMM d, y` → `Oct 3, 2025` |

  Les motifs sont des clés ARB (`dateShortPattern`, `dateLongPattern`) : le français garde exactement les motifs actuels, donc une sortie identique à la 1.0.2.

  `relativeDays` reste un simple placeholder (toujours ≥ 2, pas de pluriel ICU nécessaire).
- `_bannerDate` ([lib/features/summary/summary_screen.dart:604-609](../../lib/features/summary/summary_screen.dart)) teste aujourd'hui le texte français (`startsWith('il y a')`, `'hier'`, `'à l\'instant'`) pour préfixer « le » aux dates absolues. Il est remplacé par un test sur la date : `isAbsoluteDate(date, now)` dans `labels.dart` (vrai à partir de 7 jours calendaires, même calcul que `relativeDate`), et la clé `summaryBannerOnDate(date)` : fr `le {date}`, en `on {date}`.
- `percent(ratio)` ([lib/core/labels.dart:80](../../lib/core/labels.dart)) passe par la clé `percentValue(value)` : fr `{value} %` (espace normale, sortie identique à aujourd'hui), en `{value}%`.
- `compactNumber(value)` : `NumberFormat.compact(locale: localeName)`.
- Accès dans les widgets : extension `context.l10n` dans `lib/l10n/l10n.dart` (`extension L10nX on BuildContext { AppLocalizations get l10n => AppLocalizations.of(this); }`).
- Les valeurs de `app_fr.arb` sont les littéraux actuels recopiés tels quels (mêmes espaces, apostrophes et ponctuation) : l'inventaire des clés est produit par l'extraction elle-même, un littéral = une clé. Le domaine est le préfixe de la clé, qui reprend le fichier d'origine (`home…`, `summary…`, `settings…`, `setup…`, `keyForm…`, `error…`, `emotion…`, `common…`) : deux littéraux identiques du même fichier partagent une clé, ceux de fichiers différents ont chacun la leur. Aucune reformulation du français.
- Les fonctions sans `BuildContext` (`errorCopy`, `emotionLabel`, `sentimentLabel`, `toxicityLabel`, `relativeDate`, `compactNumber`) prennent un paramètre `AppLocalizations l` (et `relativeDate`/`compactNumber` le code de langue `l.localeName`). `errorCopy(error, l, {String? providerLabel})` : sans `providerLabel`, le texte générique vient de l'ARB (« the provider » / « le fournisseur »).
- Les textes anglais sont écrits d'après le ton de la copie française (tutoiement → « you », phrases courtes, pas de jargon) et ce glossaire, à appliquer partout :

| fr | en |
|---|---|
| Réglages | Settings |
| Résumé / Résumer | Summary / Summarize |
| Historique | History |
| Clé IA | AI key |
| Fournisseur IA | AI provider |
| Modèle | Model |
| Voir un exemple | See an example |
| Traduire en français | Translate to French |
| Avis de l'IA | AI take |
| Toxicité faible / modérée / élevée | Low / Moderate / High toxicity |
| Effacer l'historique | Clear history |
| Réessayer | Try again |
| Langue de l'appareil | Device language |

  Le fichier `app_en.arb` complet est relu par l'utilisateur avant le merge dans `develop` (étape bloquante, voir critère 14).

**2. Choix de la langue.**

- `lib/l10n/app_language.dart` :

```dart
/// What the « Langue » setting stores: follow the device, or one language.
sealed class AppLanguage { ... }
// AppLanguage.system  → stocké 'system'
// AppLanguage.fixed(Locale) → stocké le code, ex. 'fr', 'en'

/// The locale the app shows for [setting] on a device whose languages are
/// [device], among the languages the app has ([supported]).
Locale resolveAppLocale(AppLanguage setting, List<Locale> device,
    {List<Locale> supported = AppLocalizations.supportedLocales});
```

  - `fixed(locale)` → cette locale.
  - `system` → la première langue de `device` dont le `languageCode` figure dans `supported` ; à défaut, `Locale('en')`. (Aujourd'hui : `fr*` → français, tout le reste → anglais. Une langue ajoutée plus tard est prise automatiquement.)
  - La locale renvoyée n'a jamais de code pays : toujours `Locale(languageCode)` (`Locale('fr')`, jamais `Locale('fr', 'CA')`). Partout où le code compare une langue, il utilise `Localizations.localeOf(context).languageCode` (exposé par `context.appLanguageCode` dans `lib/l10n/l10n.dart`), jamais `localeName`.
- `SettingsRepository` : clé `appLanguage`, `Future<AppLanguage> appLanguage()` (absente ou inconnue → `system`) et `Future<void> setAppLanguage(AppLanguage)`.
- `lib/app/providers.dart` :
  - `deviceLocalesProvider` : `NotifierProvider<DeviceLocales, List<Locale>>`, valeur initiale `PlatformDispatcher.instance.locales`, méthode `update(List<Locale>)`.
  - `appLanguageProvider` : `NotifierProvider<AppLanguageNotifier, AppLanguage>` ; `build()` renvoie la valeur chargée au démarrage (voir ci-dessous) ; `set(AppLanguage)` écrit dans `SettingsRepository` puis met à jour l'état.
  - `appLocaleProvider` : `Provider<Locale>` = `resolveAppLocale(ref.watch(appLanguageProvider), ref.watch(deviceLocalesProvider))`.
- Démarrage sans clignotement : dans `lib/main.dart`, après `AppDatabase.open()`, lire `await SettingsRepository(database).appLanguage()` et la passer au `ProviderScope` (`initialAppLanguageProvider.overrideWithValue(language)`, lu par `AppLanguageNotifier.build()`). Le premier écran est donc déjà dans la bonne langue.
- Changement de langue de l'appareil pendant que l'app tourne : `_TldrAppState` (déjà `ConsumerStatefulWidget`, [lib/app/app.dart:18](../../lib/app/app.dart)) ajoute `WidgetsBindingObserver`, s'enregistre dans `initState`, se retire dans `dispose`, et `didChangeLocales(locales)` appelle `ref.read(deviceLocalesProvider.notifier).update(locales ?? const [])`.
- `MaterialApp.router` : `locale: ref.watch(appLocaleProvider)`, `supportedLocales: AppLocalizations.supportedLocales`, `localizationsDelegates: AppLocalizations.localizationsDelegates`. Le changement est immédiat, sans redémarrage.
- `lib/main.dart` : `initializeDateFormatting()` sans argument (toutes les langues de `intl`), à la place de `'fr_FR'`.
- La langue de l'app est lue avant le premier écran (comme le reste des réglages) pour éviter un écran en anglais qui bascule en français.

**3. Réglage « Langue » dans l'écran Réglages.**

- Nouvelle ligne `ListTile` « Langue » / « Language » entre « Modèle » et « Effacer l'historique », dont le sous-titre affiche le choix courant. Un appui ouvre une feuille modale (`showModalBottomSheet`) avec une liste à choix unique faite comme la liste des fournisseurs de [lib/features/setup/setup_screen.dart:121](../../lib/features/setup/setup_screen.dart) (`RadioListTile`, cibles de 56 dp, mêmes styles) : d'abord « Langue de l'appareil » / « Device language », puis chaque langue de `AppLocalizations.supportedLocales` écrite dans sa propre langue (`English`, `Français`), triées par `languageName` avec `String.compareTo`. Choisir une entrée ferme la feuille et applique la langue.
- Le widget de la liste (`LanguagePicker`, `lib/features/settings/language_picker.dart`) reçoit `locales` en paramètre (par défaut `AppLocalizations.supportedLocales`), ce qui permet de vérifier par test qu'une langue de plus ajoute une entrée sans toucher au widget.
- Le nom de chaque langue vient d'une clé `languageName` présente dans chaque ARB (`"languageName": "Français"`), lue via `lookupAppLocalizations(locale).languageName` : ajouter une langue ne demande aucun changement dans l'écran.
- La ligne « Version » affiche la vraie version de l'app au lieu de `'Version 1.0.0'` : ajouter la dépendance `package_info_plus` (absente aujourd'hui) et lire `PackageInfo.fromPlatform().version`.

**4. Traduction des résumés selon la langue de l'app.**

- `SummaryEntry` ([lib/data/db/summaries_dao.dart](../../lib/data/db/summaries_dao.dart)) : remplacer `displayed` et `canTranslate` par
  - `Analysis displayedIn(String appLanguage)` → `appLanguage == 'fr' && displayLang == 'fr' && analysisFr != null ? analysisFr! : analysis` ;
  - `bool canTranslateIn(String appLanguage)` → `appLanguage == 'fr' && analysis.language != 'fr'`.
- Les appels (`summary_screen.dart:296`, `:520`, `:559`, `home_screen.dart:137`) passent `context.appLanguageCode`.
- Aucun changement de schéma : `analysis_fr_json` et `display_lang` restent tels quels. En anglais, `display_lang` n'est ni lu ni modifié.

**5. Contenus embarqués.**

- `assets/demo/summary_en.json` : le même exemple que `summary_fr.json`, rédigé en anglais (même thread, mêmes champs, `language: "en"`). Le chargeur de l'exemple ([lib/features/summary/summary_screen.dart:91](../../lib/features/summary/summary_screen.dart), aujourd'hui `rootBundle.loadString('assets/demo/summary_fr.json')`) prend `assets/demo/summary_<langue de l'app>.json`, et `summary_en.json` si le fichier n'existe pas.
- `assets/catalog.json` : `"Gemini Pro (dernière version)"` devient `"Gemini Pro Latest"` (nom de marque, comme les autres modèles). Mettre à jour l'attente de `test/data/service_test.dart:96` (seul test qui cite ce nom) ; `test/data/fixtures_test.dart` reste vert.
- Les tests et aides qui chargent `summary_fr.json` (`test/helpers.dart:26`, `test/fake_tldr_api.dart:25`, `test/data/fixtures_test.dart:15`, `test/data/summaries_dao_test.dart`) restent sur le français ; `fixtures_test.dart` vérifie aussi `assets/demo/summary_en.json`.

**6. Déclaration aux systèmes (réglage de langue par app d'Android 13+ et d'iOS).**

- `ios/Runner/Info.plist` : `CFBundleLocalizations` = `en`, `fr`.
- Android : `android/app/src/main/res/xml/locales_config.xml` (`en`, `fr`), référencé par `android:localeConfig="@xml/locales_config"` sur `<application>`. Quand l'utilisateur choisit une langue dans les réglages système, l'app la reçoit comme langue de l'appareil et le mode « Langue de l'appareil » l'applique.

**7. Documentation.**

- `docs/spec/tldr-plus-spec.md` : nouvelle section « Langues » (règle de choix, réglage, traduction des résumés selon la langue), et D-9 renvoie vers elle.
- `DESIGN.md` : « French UI » devient « French and English UI (lib/l10n) ».
- `CLAUDE.md` : une ligne sous Architecture : textes affichés uniquement dans `lib/l10n/app_*.arb`, jamais en littéral dans les widgets ; ajouter une langue = ajouter `app_xx.arb`.

## Acceptance Criteria

1. Appareil en anglais, réglage « Langue de l'appareil » : aucune chaîne française n'apparaît sur l'accueil, l'historique, la configuration de la clé, les réglages, l'écran résumé (chargement, résumé, exemple) et les messages d'erreur. Un appareil en espagnol (`es_ES`) donne le même résultat.
2. Appareil en français (`fr_FR`, `fr_CA`), réglage « Langue de l'appareil » : chaque écran affiche exactement les mêmes textes qu'en 1.0.2, à trois exceptions voulues près : le nom de modèle « Gemini Pro Latest » (au lieu de « Gemini Pro (dernière version) »), la nouvelle ligne « Langue » et la vraie version dans les réglages.
3. Réglage « Français » sur un appareil en anglais : toute l'app passe en français immédiatement, sans redémarrage, et le reste après un redémarrage de l'app. Réglage « English » sur un appareil en français : même chose en anglais.
4. App en français, résumé d'un thread anglais : le bouton « Traduire en français », puis le sélecteur `VO (EN) | FR`, se comportent comme en 1.0.2.
5. App en anglais : ni le bouton de traduction ni le sélecteur n'apparaissent, pour un résumé neuf comme pour un résumé déjà traduit (`display_lang = 'fr'` en base) ; le résumé affiché et le texte partagé sont l'original. Repasser l'app en français réaffiche le sélecteur avec la traduction enregistrée, sans nouvel appel au fournisseur IA.
6. Les dates relatives et les nombres compacts suivent la langue de l'app (« il y a 2 jours » / « 2 days ago », « 1,2 k » / « 1.2K »).
7. « Voir un exemple » montre l'exemple anglais quand l'app est en anglais et l'exemple français quand elle est en français.
8. Ajouter une langue ne demande que `lib/l10n/app_xx.arb` (et sa déclaration iOS / Android) : `resolveAppLocale` et `LanguagePicker` lisent la liste des langues au lieu de la coder. Vérifié par deux tests : `LanguagePicker(locales: [en, fr, de])` affiche 4 entrées, et `resolveAppLocale(system, [Locale('de')])` avec une liste `[en, fr, de]` renvoie `de`.
9. Aucun texte anglais ne déborde ni ne se coupe sur un téléphone de 360 dp de large, avec le texte système à 100 % et à 200 % (les tests de texte à 200 % existants passent en anglais comme en français).
10. Android 13+ et iOS : choisir « Français » pour TL;DR+ dans les réglages du système affiche l'app en français avec le réglage « Langue de l'appareil ».
11. `fvm flutter analyze` sans avertissement, `build/untranslated_messages.json` vide (toutes les clés existent dans les deux langues), et aucun littéral de texte affiché ne reste dans `lib/features/`, `lib/core/` et `lib/app/`. Vérifié par `test/l10n/no_ui_literals_test.dart` : il lit ces fichiers et échoue sur tout littéral passé à `Text(`, `label:`, `title:`, `content:`, `tooltip:`, `semanticsLabel:`, `hintText:`, `labelText:` ou `SnackBar(` qui contient une lettre, sauf la liste blanche `TL;DR+`, `Reddit`, `r/` et les noms de fournisseurs (`ProviderId.label`).
12. Chaque test du Testing Plan indique sa fiche : `protects=<ce qu'il protège>; fails_when=<le mauvais résultat qu'il rejette>; no_claim=<ce que le vert ne prouve pas>`.
13. Aucune régression : la suite complète passe, et un vrai résumé (`tool/live_summary.sh`) réussit sur le simulateur iOS et l'émulateur Android avant le merge dans `develop`.
14. L'utilisateur a relu et validé `app_en.arb` avant le merge dans `develop`.

## Testing Plan

| Couche | Quoi | Nombre |
|---|---|---|
| Unit | `resolveAppLocale` : `system` + `fr_FR` → fr, `fr_CA` → fr, `en_US` → en, `es_ES` → en, liste vide → en, `[es, fr]` → fr ; `fixed(fr)` sur un appareil anglais → fr | +7 |
| Unit | `SettingsRepository.appLanguage` : absent → system, valeur inconnue → system, aller-retour `fr` / `en` / `system` | +3 |
| Unit | `SummaryEntry.displayedIn` / `canTranslateIn` en `fr` et en `en`, avec et sans traduction, `display_lang` `orig` / `fr` | +4 |
| Unit | `errorCopy`, `emotionLabel`, `sentimentLabel`, `toxicityLabel`, `relativeDate`, `compactNumber` en `en` et en `fr` (tests existants de `labels_test` conservés en français) | +6 |
| Unit | Les deux ARB ont exactement les mêmes clés et les mêmes placeholders | +1 |
| Unit | `no_ui_literals_test` (critère 11) | +1 |
| Unit | Critère 8 : `LanguagePicker` à 3 langues → 4 entrées ; `resolveAppLocale` avec une langue ajoutée | +2 |
| Widget | Accueil et réglages sous `Locale('en')` : textes anglais attendus, aucun texte français | +2 |
| Widget | Réglage « Langue » : choisir « Français » sous un appareil anglais bascule l'app sans redémarrage ; la liste compte `supportedLocales.length + 1` entrées | +2 |
| Widget | Résumé d'un thread anglais : bouton de traduction présent en `fr`, absent en `en` ; résumé déjà traduit en `en` affiche l'original et pas de sélecteur | +3 |
| Widget | Exemple : `summary_en.json` en `en`, `summary_fr.json` en `fr` | +1 |
| Widget | Tests de texte à 200 % existants rejoués sous `Locale('en')` | existants × 2 |
| Widget | Accueil, configuration de la clé, réglages, résumé et écran d'erreur sous `Locale('en')` à 360 × 800 dp, texte à 100 % puis 200 % : aucun débordement (`tester.takeException()` nul, aucun `RenderFlex overflowed`) | +5 |
| Unit | `_bannerDate` / `isAbsoluteDate` : 6 jours → relatif sans préfixe, 7 jours → « le 3 oct. » / « on Oct 3 » | +2 |
| Unit | `relativeDate` en `en` sur les 7 branches du tableau ci-dessus ; `percent` en `fr` (`45 %`) et `en` (`45%`) | +2 |
| Unit | Parité 1.0.2 en français (critère 2) : sous `Locale('fr')`, `compactNumber(1234)`, `compactNumber(56789)`, `relativeDate` (date à 10 jours, même année et autre année), `percent(0.45)` et `errorCopy` pour chaque code donnent exactement les chaînes de la 1.0.2 (valeurs relevées sur `b4564ba` avant l'extraction) | +1 |
| Manuel | Critère 10 : Android 13+ (Réglages > Système > Langues > Langues des applis) et iOS (Réglages > TL;DR+ > Langue) en français, app en « Langue de l'appareil » → app en français ; capture d'écran jointe au merge | 2 |
| Live | `tool/live_summary.sh` sur iOS et Android (inchangé, il ne dépend pas de la langue de l'interface) | 2 runs |

Les tests existants qui vérifient du texte français (`test/widget/app_test.dart`, `test/core/labels_test.dart`, `test/data/service_test.dart`) fixent `Locale('fr')` et restent inchangés pour le reste.

## Rules for the implementing agent

1. Acceptance criteria are the `protects / fails_when / no_claim` profile of each test: the observable it protects, the wrong result it rejects, and what green does not prove. Never "make the tests pass".
2. Real code and real tests land in the same change; a placeholder, a stub assertion or a test deferred to a follow-up is not done.
3. Any change to a test, validator, CI step, timeout, tolerance, threshold, snapshot or suppression pragma is reported on its own line in your summary with its justification, before any other result.
4. A reported command names the command and its observed result (exit status, counts, the failing line); a command you did not run is not reported, and stderr is never silenced in a command you cite.
5. Your report is a claim until the parent re-executes it: say what you verified, what you reused, and what you could not check.

## Rollback Plan

Aucune donnée n'est migrée : la clé `appLanguage` s'ajoute à la table `settings` existante, et `analysis_fr_json` / `display_lang` ne changent pas. Rollback = revert du merge sur `develop` (ou republier la 1.0.2 si la 1.1.0 est déjà sur les stores) ; une 1.0.2 ignore simplement la clé `appLanguage`.

## Effort Estimate

| Partie | Humain | Claude Code |
|---|---|---|
| Mise en place `gen-l10n`, `l10n.yaml`, extension `context.l10n` | 1 h | 10 min |
| Extraction des ~165 textes vers `app_fr.arb` + rédaction de `app_en.arb` | 6 h | 45 min |
| `errorCopy` et `labels.dart` paramétrés, dates et nombres | 2 h | 15 min |
| Réglage « Langue », providers, `MaterialApp` | 2 h | 20 min |
| Traduction des résumés selon la langue, exemple anglais, catalogue | 2 h | 20 min |
| Déclarations iOS / Android | 0,5 h | 5 min |
| Tests (≈ 30 nouveaux) et docs | 4 h | 40 min |
| Vérification sur appareils (deux langues, 200 %, vrai résumé) | 2 h | 30 min |
| **Total** | **≈ 19,5 h** | **≈ 3 h** |

## Files Reference

| Fichier | Changement |
|---|---|
| `pubspec.yaml` | `flutter_localizations`, `generate: true`, `package_info_plus`, version 1.1.0 |
| `l10n.yaml` | nouveau |
| `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb` | nouveaux : tous les textes |
| `lib/l10n/app_localizations*.dart` | générés |
| `lib/l10n/l10n.dart` | extensions `context.l10n` et `context.appLanguageCode` |
| `lib/l10n/app_language.dart` | `AppLanguage`, `resolveAppLocale` |
| `lib/main.dart` | `initializeDateFormatting()` toutes langues ; langue lue avant `runApp` et passée au `ProviderScope` |
| `lib/app/app.dart` | `locale`, `supportedLocales`, `localizationsDelegates` (`:105`) ; `WidgetsBindingObserver.didChangeLocales` ; snackbars |
| `lib/app/providers.dart` | `deviceLocalesProvider`, `initialAppLanguageProvider`, `appLanguageProvider`, `appLocaleProvider` |
| `lib/data/settings/settings_repository.dart` | clé `appLanguage` |
| `lib/data/db/summaries_dao.dart:61-64` | `displayedIn`, `canTranslateIn` |
| `lib/core/errors.dart` | `errorCopy(error, l, ...)` |
| `lib/core/labels.dart` | libellés et formats paramétrés par la langue ; `isAbsoluteDate` ; `percent` |
| `lib/core/widgets/common.dart:54` | libellé d'accessibilité |
| `lib/features/home/home_screen.dart` | textes ; `displayedIn` au partage (`:137`) |
| `lib/features/summary/summary_screen.dart` | textes ; `displayedIn` / `canTranslateIn` (`:296`, `:520`, `:559`) ; `_LanguageControl` ; `_bannerDate` (`:604-609`) |
| `lib/features/summary/summary_widgets.dart` | textes |
| `lib/features/setup/setup_screen.dart` | textes |
| `lib/features/settings/settings_screen.dart` | textes, ligne « Langue », vraie version |
| `lib/features/settings/key_form.dart` | textes |
| `lib/features/settings/language_picker.dart` | nouveau : liste à choix unique des langues |
| `lib/features/summary/summary_screen.dart:91` | chargeur de l'exemple : fichier choisi par langue |
| `assets/demo/summary_en.json` | nouveau |
| `assets/catalog.json` | « Gemini Pro Latest » |
| `ios/Runner/Info.plist` | `CFBundleLocalizations` |
| `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/res/xml/locales_config.xml` | langues déclarées |
| `test/l10n/`, `test/core/`, `test/data/`, `test/widget/` | nouveaux tests (Testing Plan) ; `Locale('fr')` fixée dans les tests existants ; `test/data/service_test.dart:96` (nom du modèle) |
| `docs/spec/tldr-plus-spec.md`, `DESIGN.md`, `CLAUDE.md` | section « Langues », mentions de langue |

## Out of Scope

- « Translate to English » (traduire un résumé vers l'anglais quand l'app est en anglais), et plus généralement la traduction vers une autre langue que le français.
- Toute autre langue que le français et l'anglais (la structure les permet, aucune n'est ajoutée).
- La langue des résumés eux-mêmes : ils restent dans la langue du thread.
- Les fiches Google Play et App Store en anglais : à faire à la main par l'utilisateur avant de poster sur Reddit (rappel à lui faire au moment de la livraison 1.1.0).
- Les langues écrites de droite à gauche.

## Related

- Rappel : mettre à jour la fiche Google Play (et App Store) en anglais avant de publier sur Reddit.
- Spec produit : `docs/spec/tldr-plus-spec.md` (D-9 Traduction, D-7 Erreurs).
