# tldr

Flutter mobile app that summarizes Reddit threads with the user's own LLM API key (Gemini, Anthropic or OpenAI).

## Architecture

Everything runs on the device: there is no backend and no mock mode. Don't reintroduce either.

- `SummaryService` (lib/data/summary_service.dart) → `TldrApi` → `DirectTldrApi` (lib/data/engine/): reads the Reddit thread, selects comments, calls the user's AI provider over REST.
- Reddit refuses anonymous `.json` requests from HTTP clients. Without `REDDIT_CLIENT_ID`, threads are read through a WebView (lib/data/engine/reddit_page.dart) that the Summary screen shows, then dissolves into dust (lib/features/summary/dust_veil.dart) while the AI writes. With an approved client id, `LiveRedditClient` uses OAuth instead.
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

## Design System
Read DESIGN.md before visual or UI work: it defines the fonts, colors, spacing, and
aesthetic direction. Ask the user before departing from it. When reviewing or QA-ing
UI, flag code that doesn't match DESIGN.md.
