---
# gstack: design-md-format=spec
name: TL;DR+
description: Céladon — a cool celadon glaze in fog; flat, quiet surfaces where a Reddit thread settles into composed prose.
colors:
  primary: "#2F5D57"
  on-primary: "#FFFFFF"
  surface: "#EEF1EC"
  surface-container-high: "#E2E7E1"
  surface-container-highest: "#D8DED7"
  text: "#1D2422"
  text-muted: "#4E5A56"
  outline: "#75817C"
  outline-variant: "#C5CDC7"
  tertiary: "#3E5B7A"
  error: "#B3261E"
  on-error: "#FFFFFF"
  sentiment-positive: "#2E6B3F"
  sentiment-negative: "#8A4B14"
  accent: "#FF4500"
  primary-dark: "#9CCFC6"
  on-primary-dark: "#00352F"
  surface-dark: "#121816"
  surface-container-high-dark: "#1F2724"
  surface-container-highest-dark: "#29322F"
  text-dark: "#DDE4E0"
  text-muted-dark: "#A3B0AB"
  outline-dark: "#87938E"
  outline-variant-dark: "#3A4541"
  tertiary-dark: "#A9C4E6"
  error-dark: "#FFB4AB"
  on-error-dark: "#690005"
  sentiment-positive-dark: "#8FD19E"
  sentiment-negative-dark: "#E8B27A"
  accent-dark: "#FF6A33"
typography:
  wordmark:
    fontFamily: IBM Plex Sans
    fontWeight: 600
    fontSize: 20px
    lineHeight: 24px
    letterSpacing: -0.2px
  title-thread:
    fontFamily: IBM Plex Sans
    fontWeight: 600
    fontSize: 24px
    lineHeight: 30px
  title-screen:
    fontFamily: IBM Plex Sans
    fontWeight: 600
    fontSize: 20px
    lineHeight: 28px
  section-label:
    fontFamily: IBM Plex Sans
    fontWeight: 600
    fontSize: 14px
    lineHeight: 20px
  reading-lead:
    fontFamily: Literata
    fontWeight: 400
    fontSize: 20px
    lineHeight: 30px
  reading-body:
    fontFamily: Literata
    fontWeight: 400
    fontSize: 17px
    lineHeight: 27px
  reading-opinion:
    fontFamily: Literata
    fontWeight: 400
    fontSize: 16px
    lineHeight: 25px
  verdict:
    fontFamily: IBM Plex Sans
    fontWeight: 500
    fontSize: 15px
    lineHeight: 22px
  body:
    fontFamily: IBM Plex Sans
    fontWeight: 400
    fontSize: 16px
    lineHeight: 24px
  list-title:
    fontFamily: IBM Plex Sans
    fontWeight: 500
    fontSize: 16px
    lineHeight: 22px
  meta:
    fontFamily: IBM Plex Sans
    fontWeight: 400
    fontSize: 13px
    lineHeight: 18px
  label:
    fontFamily: IBM Plex Sans
    fontWeight: 500
    fontSize: 14px
    lineHeight: 20px
  caption:
    fontFamily: IBM Plex Sans
    fontWeight: 400
    fontSize: 12px
    lineHeight: 16px
    fontFeature: tnum
rounded:
  none: 0px
  xs: 4px
  sm: 6px
  md: 8px
  lg: 12px
spacing:
  xxs: 4px
  xs: 8px
  sm: 12px
  md: 16px
  gutter: 20px
  lg: 24px
  xl: 32px
  section: 48px
  xxl: 72px
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    rounded: "{rounded.md}"
  button-tonal:
    backgroundColor: "{colors.surface-container-highest}"
    textColor: "{colors.text}"
    rounded: "{rounded.md}"
  input:
    borderColor: "{colors.outline}"
    rounded: "{rounded.sm}"
  url-field:
    backgroundColor: "{colors.surface-container-high}"
    rounded: "{rounded.sm}"
  ai-opinion:
    backgroundColor: "{colors.surface-container-highest}"
    rounded: "{rounded.lg}"
  nsfw-badge:
    backgroundColor: "{colors.error}"
    textColor: "{colors.on-error}"
    rounded: "{rounded.xs}"
---

# TL;DR+

## Overview

**Creative North Star:** « Le calme après le bruit ». Reddit is warm, orange and loud; TL;DR+ is cool, celadon and quiet. The calm comes from colour temperature and reading typography, not from decoration.
**Product context:** Flutter Material 3 app (Android + iOS) that summarizes Reddit threads with the user's own AI key. Personal use first. French UI. Spec: `docs/spec/tldr-plus-spec.md`, section « App mobile > Design » (D-1 to D-22).
**Mode per surface:** Home, Settings, Setup = Operate. Summary = Read.
**Reference sites:** none (competitive research declined; built from design knowledge).
**Key characteristics:**
- The first thing read on a summary is a large Literata paragraph, « En bref ».
- No cards, no shadows: flat celadon surfaces, spacing and hairlines do the structure.
- The verdict is one sentence, not a dashboard.
- Reddit orange appears only as a small provenance mark.

## Colors

**Strategy:** Restrained. Neutrals carry a slight green cast derived from the celadon primary; colour is rare and always means something.
**Light or dark:** the app is read in passing, day and night, right after the Reddit app. It follows the system theme (`ThemeMode.system`); both themes are first-class.

- `primary` marks interaction only: filled buttons, selected segment, focus, links. Never decorative fills.
- `surface-container-high` is the URL field well; `surface-container-highest` is the single tinted block (« L'avis de l'IA ») and selected states.
- Sentiment colours apply to the sentiment word and its 8 dp dot only. Negative is amber-brown on purpose so it never reads as an error; `error` is reserved for errors, high toxicity and the NSFW badge.
- `accent` (Reddit orange) is « the door back to the noise »: a 6 dp square before every `r/sub`, the « Ouvrir dans Reddit » icon, and the « + » of the wordmark. Never text, never an action, never a fill. On light surfaces it reaches 3.0:1, enough for a non-text mark, not for text.
- Dark mode is not an inversion: surfaces become deep pond greens (`#121816` → `#29322F`), hierarchy is kept by lightness steps between containers, and primary becomes a pale celadon.
- Flutter mapping: build `ColorScheme(brightness: …)` explicitly from these tokens (no `fromSeed`); `secondary` = `tertiary`; `onSurfaceVariant` = `text-muted`.

Verified contrasts (WCAG): text on surface 13.9:1 (light) / 13.9:1 (dark); text-muted 6.3:1 / 8.0:1; primary on surface 6.5:1 / 10.4:1; positive 5.6:1 / 10.1:1; negative 6.0:1 / 9.5:1; error 5.7:1 / 10.6:1.

## Typography

Two faces, both from Google Fonts, **bundled as assets** (`assets/fonts/`, OFL licences in `assets/fonts/LICENSES/`), never downloaded at runtime:
- **IBM Plex Sans** (400, 500, 600) for every UI element. Plex is normally excluded as a display voice; the only display-like use here is the 20 sp wordmark inside the app bar, accepted because it is a logo in an Operate surface, not a headline.
- **Literata** (400, 400 italic, 600), a serif designed for screen reading, used **only** for summary content: `reading-lead` (« En bref »), `reading-body` (« Points de vue »), `reading-opinion` (« L'avis de l'IA »).

The switch of face is the signal: Plex means « you are operating the app », Literata means « you are reading the thread ». Sizes are in sp in Flutter (1px in the tokens = 1 sp/dp). All styles must survive 200 % text scaling (spec D-18). Captions use tabular figures.

| Element | Token |
|---|---|
| Wordmark « TL;DR+ » | `wordmark` |
| Thread title on Summary | `title-thread` (max 3 lines) |
| Screen titles (Réglages, Setup) | `title-screen` |
| « En bref », « Points de vue », « L'avis de l'IA », « Récents » | `section-label`, sentence case, never uppercase |
| « En bref » text | `reading-lead` |
| « Points de vue » text | `reading-body` |
| « L'avis de l'IA » text | `reading-opinion` |
| Verdict line | `verdict` |
| URL field, inputs, setup body | `body` |
| History title | `list-title` (max 2 lines) |
| `r/sub · date · provider` | `meta` |
| Buttons, segmented controls | `label` |
| Stats footer, help text | `caption` |

## Layout

- One reading column, `maxWidth: 640` dp, centred (spec D-19); app bar full width.
- Screen gutter `spacing.gutter` (20 dp), deliberately off the 16 dp default for a slightly calmer measure.
- 4 dp grid. Inside a block (label → text) `spacing.xs`; between summary sections `spacing.section` (48 dp, replaces the 32 dp of spec D-14); title → « En bref » `spacing.md`.
- History rows: `spacing.md` vertical padding, `outline-variant` hairline inset by the gutter.
- Breakpoints: phone portrait is the design target; landscape and tablet keep the same column via the max width, no two-column layout.

## Elevation & Depth

None. Every surface has `elevation: 0`; the app bar uses `scrolledUnderElevation: 0` and switches to `surface-container-high` when content scrolls under it. Depth is expressed by container lightness steps only. No shadows, no glows, no blur.

## Shapes

- `rounded.none`: lists, screen edges, dividers.
- `rounded.xs` (4): NSFW badge, skeleton blocks.
- `rounded.sm` (6): URL field, API key field, model picker, segmented controls.
- `rounded.md` (8): buttons.
- `rounded.lg` (12): « L'avis de l'IA », the only tinted container, and the softest corner in the app.
- No pill shapes, including the URL field (a soft rectangle rather than the M3 pill SearchBar shape).

## Components

- **Filled button** (`button-primary`): pressed = primary at 88 % opacity; disabled = text-muted at 38 % on surface-container-high; focus-visible = 2 dp `primary` outline offset 2 dp.
- **Tonal button** (`button-tonal`): used for « Résumer » next to the URL field.
- **URL field** (`url-field`): no border; 52 dp high; leading paste icon (48 dp target); helper text in `error` when the link is not Reddit.
- **Inputs** (`input`): 1 dp `outline` border, 2 dp `primary` when focused, visible label above (never placeholder-as-label).
- **Segmented control**: 1 dp `outline` border, selected segment filled `surface-container-highest`, no check icon.
- **History row**: no card; title, meta with the orange 6 dp square, optional NSFW badge, trailing sentiment emoji.
- **« L'avis de l'IA »** (`ai-opinion`): 16 dp padding, 18 dp outline icon before the label, **no coloured edge**.
- **Verdict line**: 8 dp sentiment dot + sentiment word in its colour, emotions in `text`, « +N » and toxicity in `text-muted` (high toxicity in `error`).
- **Skeleton** (spec D-6): `surface-container-highest` blocks, `rounded.xs`.

## Do's and Don'ts

- Do keep Literata strictly inside summary content.
- Do use `primary` only for things the user can act on.
- Do keep the orange as a mark: 6 dp square, icon or the wordmark « + ».
- Do check every new text colour at 4.5:1 in both themes.
- Don't add a `Card`, a shadow or a second tinted container.
- Don't colour the edge of a container (no left border accents).
- Don't put text or buttons in Reddit orange, and never seed the scheme from it.
- Don't uppercase or letter-space section labels.
- Don't use emoji on the Summary screen (history only).

## Motion

- **Approach:** minimal-functional (spec D-16).
- **Easing:** enter `Curves.easeOut`, exit `Curves.easeIn`, move `Curves.easeInOut`.
- **Duration:** micro 100 ms, short 200 ms, medium 250 ms.
- **The one authored moment:** the skeleton fading into the summary (250 ms ease-out). Everything is disabled when the system asks to reduce motion.

## Decisions Log
| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-10-08 | Initial design system « Céladon » created | /design-consultation from the memorable thing « le calme après le bruit »; palette from the independent Claude subagent proposal, Literata-only-in-content rule from the cursor-agent proposal; fonts verified on Google Fonts; contrasts verified |
| 2026-10-08 | Section gap 48 dp and gutter 20 dp | Replace spec D-14 (32 dp) and D-2 (16 dp) for a calmer reading rhythm |
