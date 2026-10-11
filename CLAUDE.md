# tldr

Flutter mobile app that summarizes Reddit threads with the user's own LLM API key (Gemini, Anthropic or OpenAI).

## Architecture

Everything runs on the device: there is no backend and no mock mode. Don't reintroduce either.

- `SummaryService` (lib/data/summary_service.dart) → `TldrApi` → `DirectTldrApi` (lib/data/engine/): reads the Reddit thread, selects comments, calls the user's AI provider over REST.
- Reddit refuses anonymous `.json` requests from HTTP clients, and the app must not rely on Reddit's OAuth API (expected to go away): threads are read through a WebView (lib/data/engine/reddit_page.dart) that the Summary screen shows, then dissolves into dust (lib/features/summary/dust_veil.dart) while the AI writes. No build-time config is needed.
- Tests replace `TldrApi` with `FakeTldrApi` (test/fake_tldr_api.dart, fixtures in test/fixtures/). The only bundled sample is the « Voir un exemple » summary (assets/demo/).
- Spec: docs/spec/tldr-plus-spec.md. Git flow: features branch off `develop`; `main` only gets releases.

## Skill routing

When the user's request matches an available skill, invoke it via the Skill tool. Route only to skills in the session's available-skills list; answer directly for quick questions or small scoped edits.

Key routing rules:
- Product ideas/brainstorming → invoke /office-hours
- Strategy/scope → invoke /plan-ceo-review
- Architecture → invoke /plan-eng-review
- Design system/plan review → invoke /design-consultation or /plan-design-review
- Full review pipeline → invoke /autoplan
- Bugs/errors → invoke /investigate
- QA/testing site behavior → invoke /qa or /qa-only
- Code review/diff check → invoke /review
- Visual polish → invoke /design-review
- Ship/deploy/PR → invoke /ship or /land-and-deploy
- Save progress → invoke /context-save
- Resume context → invoke /context-restore
- Author a backlog-ready spec/issue → invoke /spec

## Testing

Flutter is pinned with FVM (`.fvmrc`), so prefix commands with `fvm`. Tests live in `test/`.

- Run: `fvm flutter analyze && fvm flutter test`
- `test/live/` summarizes a real Reddit thread with the real Gemini API, using the keys in `gemini.keys` (repo root, one per line, git-ignored: never commit, print or paste them). It is skipped when the file is missing.
- Every ship (merging a feature into `develop`, or a release) needs a real summary on both platforms first, and the result reported to the user:
  - iOS simulator: `tool/live_summary.sh <simulator-id>` (`xcrun simctl list devices booted`).
  - Android emulator: start it with `~/Library/Android/sdk/emulator/emulator -avd Pixel_9_Pro &` (the user's `androidemulator` alias), then `tool/live_summary.sh emulator-5554`.
  - The script reads the thread through the Reddit WebView, summarizes it with Gemini and exits 0 on `LIVE_OK`. The tool runs under the app's id, so the script reinstalls the real app at the end.

## Design System
Read DESIGN.md before visual or UI work: it defines the fonts, colors, spacing, and
aesthetic direction. Ask the user before departing from it. When reviewing or QA-ing
UI, flag code that doesn't match DESIGN.md.
