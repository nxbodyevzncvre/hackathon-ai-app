# Decisions & assumptions

One line each. Every assumption made to remove ambiguity without asking.

- Deployment target iOS 17.0 as fixed; `@Observable` used throughout (17+ API).
- Settings persisted in `UserDefaults` via `SettingsStore`, not SwiftData — because it is flat typed data with no relationships.
- Briefing text in M4 (offline) is a template line composed from the plan ("5 actions, 2h 15m planned, 1 overdue"); the AI-written rationale (proxy `/v1/plan`) replaces it when Live is on.
- Voice capture is "should have": if M2 finishes early, `SFSpeechRecognizer` on-device gets added to the Capture sheet; if not, it is skipped without apology — Capture never ships a dead mic button.
- WeeklyStrip is computed (repository queries for completed/open counts in the current week), not stored.
- WeeklyStrip starts on Monday (the brief's audience is EU-coded; the one timezone, non-US-first assumption).
- Paywall: `StubEntitlementService` returns Pro in DEBUG; release behavior is "free limits enforced, Pro purchase shows a stub note" until real StoreKit wiring in a later milestone.
- Rate-limit counters: per-device daily/hourly window in Worker KV; device sha256 hash computed in the Worker from the bearer token, never stored raw.
- Heuristic parser (M2) recognizes a fixed grammar: date-phrases (`tomorrow`, `today`, `next week`, weekday names), verb-intent patterns for the 5 categories, and the demo sentence; anything unmatched becomes a clarification.
- Notification "stable identifier per action + offset" = `uuidstring + "-24h"/"-1h"`, so reschedule means cancel-by-id then re-add.
- The Worker source lives in `ProxyWorker/` inside this repo for versioning but is excluded from the iOS target and deployed separately; `.env` at repo root is gitignored from day one.
- Toast Undo lifetime: 5 s, single-level undo (delete last created batch), implemented in `RootView` toast host.
- Deleting all data also cancels all pending notifications and deletes the Keychain device token.
- "Deliverable: 5 questions max" — batched below.
