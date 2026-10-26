# Fiche App Store : TL;DR+

Textes à coller dans App Store Connect. Le français est la langue principale, l'anglais (U.S.) est une localisation.
Les limites d'Apple sont entre parenthèses.

## Infos générales (App Information)

| Champ | Valeur |
|---|---|
| Bundle ID | `com.bdzapps.tldr` |
| SKU | `tldr-ios` |
| Langue principale | Français (France) |
| Catégorie principale | Productivité |
| Catégorie secondaire | Actualités (facultatif) |
| URL de confidentialité | https://bdzapps.com/tldr/privacy/ |
| URL d'assistance | https://bdzapps.com/tldr/ (une page qui existe et donne un contact) |
| Prix | Gratuit |
| Chiffrement | Déjà déclaré dans l'app (`ITSAppUsesNonExemptEncryption = false`) : rien à remplir |

## Français (France)

**Nom** (30) : `TL;DR+`
Si le nom est déjà pris : `TL;DR+ Résumés`

**Sous-titre** (30) : `Résume un thread avec ton IA`

**Texte promotionnel** (170) :
> Un thread de 500 commentaires ? TL;DR+ le lit pour toi et te donne l'essentiel en quelques secondes, avec ta propre clé Gemini, Claude ou OpenAI.

**Mots-clés** (100 octets, séparés par des virgules, sans espace) :
```
résumé,thread,commentaires,IA,Gemini,Claude,OpenAI,GPT,discussion,lecture,synthèse,forum,TLDR
```

**Description** (4000) :
```
Un thread Reddit de 500 commentaires ? TL;DR+ le lit pour toi et te dit l'essentiel en quelques secondes.

COMMENT ÇA MARCHE
• Dans l'app Reddit, appuie sur Partager puis choisis TL;DR+.
• Ou colle simplement le lien du post dans l'app.
• Le post s'affiche, se dissout, et ton résumé apparaît.

CE QUE TU OBTIENS
• En bref : l'idée principale du thread en quelques lignes.
• Points de vue : les différentes positions défendues dans les commentaires.
• Le ton de la discussion : sentiment, émotions dominantes et niveau de toxicité.
• L'avis de l'IA : ce que la discussion dit vraiment, au-delà du bruit.
• Le nombre de commentaires analysés, pour savoir sur quoi repose le résumé.

TON IA, TA CLÉ
TL;DR+ fonctionne avec ta propre clé d'API Gemini (Google), Claude (Anthropic) ou OpenAI. Gemini propose une offre gratuite pour commencer.
• Ta clé est stockée dans le trousseau de ton iPhone et n'est envoyée qu'à ton fournisseur d'IA.
• Pas de compte, pas d'inscription, pas de serveur intermédiaire : l'app parle directement à Reddit et à ton IA.

PRATIQUE
• Historique de tous tes résumés, consultables hors ligne.
• Partage un résumé en un geste.
• Un exemple de résumé à découvrir sans clé, pour voir le résultat avant de te lancer.
• En français ou en anglais, au choix.

TL;DR+ n'est ni affilié à Reddit, ni approuvé par Reddit.
```

**Nouveautés** (première version) :
> Première version sur iPhone et iPad.

## English (U.S.)

**Name** (30): `TL;DR+`
If the name is taken: `TL;DR+ Summaries`

**Subtitle** (30): `Sum up any thread with your AI`

**Promotional text** (170):
> A thread with 500 comments? TL;DR+ reads it for you and gives you the gist in seconds, with your own Gemini, Claude or OpenAI key.

**Keywords** (100 bytes):
```
summary,summarize,thread,comments,AI,Gemini,Claude,OpenAI,GPT,discussion,digest,forum,TLDR
```

**Description** (4000):
```
A Reddit thread with 500 comments? TL;DR+ reads it for you and tells you what matters, in seconds.

HOW IT WORKS
• In the Reddit app, tap Share and pick TL;DR+.
• Or just paste the post's link in the app.
• The post appears, dissolves, and your summary shows up.

WHAT YOU GET
• In short: the thread's main idea in a few lines.
• Viewpoints: the different positions argued in the comments.
• The tone of the discussion: sentiment, main emotions and toxicity level.
• The AI's take: what the discussion is really saying, beyond the noise.
• How many comments were analyzed, so you know what the summary is based on.

YOUR AI, YOUR KEY
TL;DR+ works with your own Gemini (Google), Claude (Anthropic) or OpenAI API key. Gemini has a free tier to get started.
• Your key is stored in your iPhone's Keychain and is only ever sent to your AI provider.
• No account, no sign-up, no middle server: the app talks straight to Reddit and to your AI.

HANDY
• A history of all your summaries, available offline.
• Share a summary in one tap.
• A sample summary you can open without a key, to see the result before you start.
• In English or French, your choice.

TL;DR+ is not affiliated with or endorsed by Reddit.
```

**What's New** (first version):
> First release on iPhone and iPad.

## Captures

| Appareil | Dossier | Taille |
|---|---|---|
| iPhone 6,3" | `store/app-store/<fr|en>/iphone-6.3/` (5 images) | 1206 × 2622 |
| iPad 13" | `store/app-store/<fr|en>/ipad-13/` (4 images) | 2064 × 2752 |

Apple réduit lui-même ces tailles pour les autres iPhone et iPad : pas besoin d'autres formats.

## Confidentialité (App Privacy)

« Data Not Collected » (aucune donnée collectée) : l'app n'a pas de serveur, la clé reste sur l'appareil et le texte du thread part directement chez le fournisseur IA choisi par l'utilisateur, sans passer par le développeur.

## Notes pour la revue (App Review Information)

- Connexion requise : **non** (pas de compte).
- Notes (à coller, en anglais) :
```
TL;DR+ summarizes a Reddit thread with the user's own AI API key (Gemini, Claude or OpenAI). There is no account and no backend: the key is stored in the Keychain and sent only to the chosen AI provider.

To test without a key: on the home screen, tap "See an example".

To test a real summary: at first launch keep "Gemini", tap Continue and paste this Gemini API key: <CLÉ DE TEST>
Then paste a Reddit thread link (for example https://www.reddit.com/r/founder/comments/1x1wi5n/someone_copied_my_saas/) and tap Summarize. You can also share a post from the Reddit app or Safari to TL;DR+ with the share sheet.

The app is not affiliated with Reddit; it reads the public thread page the user shares, in a WebView.
```
Mets une clé Gemini **dédiée à la revue** (créée pour l'occasion, révocable) à la place de `<CLÉ DE TEST>`, jamais celle de `gemini.keys`.
