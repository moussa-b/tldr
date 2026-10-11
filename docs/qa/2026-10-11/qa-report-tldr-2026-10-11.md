# QA TL;DR+ 1.0.0 — 2026-10-11

- **Cible** : app mobile, build debug de `develop` (après la release 1.0.0).
- **Appareils** : simulateur iPhone 16 Pro (iOS 18.6), émulateur Pixel 9 Pro (Android).
- **Méthode** : parcours utilisateur pilotés à la main (taps, saisie, captures). Clé Gemini saisie par l'utilisateur (jamais par l'agent). Tier Standard (critique, haute, moyenne).
- **Captures** : `screenshots/` (`ios-*`, `android-*`).

## Résultat

3 bugs trouvés, 3 corrigés et vérifiés par un test de régression qui échoue avant le correctif et passe après. Suite complète : 79 tests, analyse propre.

| # | Sévérité | Bug | Statut | Commit |
|---|---|---|---|---|
| ISSUE-001 | Basse | Date relative « il y a 1 jours » : comptait des tranches de 24 h au lieu de jours calendaires | Corrigé, vérifié (test) | `52e713e` |
| ISSUE-002 | Moyenne | L'accueil gardait « Ajoute ta clé IA pour commencer » après avoir enregistré une clé via un lien collé | Corrigé, vérifié (test + simulateur) | `b8fda70` |
| ISSUE-003 | Moyenne | Ligne de verdict cassée : « +1 » seul sur une ligne, la toxicité repoussée en dessous | Corrigé, vérifié (test) | `5fa04ac` |

### ISSUE-001 — « il y a 1 jours »

- Repro : un post publié avant-hier il y a moins de 48 h (`screenshots/ios-14-after-key.jpg`).
- Cause : `relativeDate` (lib/core/labels.dart) utilisait `Duration.inDays`.
- Correctif : différence en jours calendaires. Test : `test/core/labels_test.dart`.

### ISSUE-002 — bannière de clé restée affichée

- Repro : sans clé, coller un lien → configuration → clé enregistrée → résumé → retour : la bannière reste (`screenshots/ios-20-home-history.jpg`).
- Cause : le résumé remplace la route que l'accueil attendait ; l'accueil revérifiait la clé à ce moment-là, avant l'enregistrement, et plus jamais ensuite.
- Correctif : `keyRevisionProvider` incrémenté à chaque enregistrement ou suppression de clé ; l'accueil l'écoute. Test : `test/widget/app_test.dart` (« a key saved on the way to a summary hides the home key banner »).

### ISSUE-003 — « +N » émotions

- Repro : un résumé avec 3 émotions (`screenshots/android-11-verdict-wrap-bug.jpg`).
- Cause : `Center` sans facteurs dans un `Wrap` prend toute la largeur.
- Correctif : `widthFactor: 1, heightFactor: 1` (la zone tactile de 48 dp reste). Test : `test/widget/verdict_line_test.dart`.

## Parcours vérifiés

| Parcours | iOS | Android |
|---|---|---|
| Premier lancement : configuration en 2 étapes, retour | ✅ | ✅ |
| « Voir un exemple » (lire plus/moins, avis de l'IA, pied de page) | ✅ | — |
| Réglages : clé vide, clé au mauvais format, clé refusée par Gemini | ✅ | — |
| Lien invalide → « Ce lien n'est pas un thread Reddit » | ✅ | — |
| Lien sans clé → configuration, puis résumé du lien gardé | ✅ | — |
| Nouveau résumé : post dans la WebView → poussière → résumé | ✅ (via la configuration) | ✅ (`android-03` à `05`) |
| Traduction en français, bascule VO/FR | ✅ | — |
| Régénérer : confirmation, WebView hors écran, traduction remise à zéro | ✅ | — |
| Thread introuvable | — | ✅ |
| Thread déjà résumé → « Déjà résumé il y a 1 min » + Régénérer | — | ✅ |
| Historique : menu appui long, suppression, annulation | — | ✅ |

## Non couvert

- **Partage depuis l'app Reddit** (intent Android, Share Extension iOS) : l'app Reddit n'est pas installée sur les appareils de test.
- **Bouton « Annuler » pendant un résumé** : Gemini a répondu avant le tap ; non vérifié.
- **Erreurs réseau** (mode avion) et quota épuisé dans l'interface : non provoqués (pas de changement de réglages système sur l'appareil).
- **Vérification visuelle d'ISSUE-003 sur appareil** : la réinstallation Android a perdu les données de l'app (outil d'installation, pas l'app) ; correctif prouvé par le test.
- **Écrans en mode sombre et texte à 200 %** : couverts par les tests widget existants, pas revus à l'œil.

## Remarques hors bugs

- Sur le simulateur, une saisie de texte injectée suit la disposition du clavier (AZERTY) : les liens se tapent mal. Utiliser le presse-papiers (`xcrun simctl pbcopy`) et le bouton Coller.
- Après un `flutter run --no-resident` raté, Android peut se retrouver sans l'app (et sans ses données) : refaire `fvm flutter run -d emulator-5554`.
