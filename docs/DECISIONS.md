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
- Toolchain is Xcode 26.6, which has no bare "iPhone 16" simulator; the build destination is `platform=iOS Simulator,name=iPhone 16 Pro` (min target stays iOS 17.0).
- Repo git history starts with the Phase A docs commit; ProxyWorker is committed to the repo but excluded from the iOS target and `.env` is ignored from the first commit.
- APPROVED: M3 is stub-first — no external proxy dependency; `ExtractionService.Live` ships flag-off and the offline heuristic path is the only active pipeline for the MVP.
- APPROVED: free limits are hard-enforced in release builds only; DEBUG builds bypass the cap and get a "Reset limits" button in Settings so rehearsal is never blocked.
- APPROVED: natural-language task edit runs on the StubTaskEditService (deterministic command parser); a live proxy implementation is coded for M3+ but kept flag-off like extraction.
- APPROVED: M6 ships a local signed archive; no TestFlight/App Store Connect upload, no Team/bundle-id provisioning work.
- APPROVED: voice capture is cut from this MVP entirely; Capture sheet is text-only with no dead mic button.
- M1 adjustments discovered while building: grouping rule is "explicit date drives the section regardless of status; Unsorted = inbox-status items without a confirmed date; undone planned items without a date go to No date" (the brief's "unsorted first" left this open); SwiftData on the Xcode 26 SDK cannot materialize `Array<Double>` attributes, so reminder offsets are stored as CSV text; the `ModelContainer` must be retained by the environment (releasing it with live contexts crashes with EXC_BREAKPOINT); Xcode 26 links the app via `Autopilot.debug.dylib` while `Autopilot` binary remains the TEST_HOST anchor; app target sources exclude Tests/.shots/project.yml/markdown so no junk ships in the bundle; `-autopilot-no-seed` launch arg disables fixture seeding; TaskDetail edits write through on each change (same contract as Settings).
- M1 TDD results: 10 new tests (5 repository incl. relaunch simulation across three container instances, 5 logic incl. sections order, category filter, weekly summary, today feed) went red → green; final suite 18/18.
- M0 adjustments discovered while building: project generated with xcodegen 2.46 (dev-time tool only); the build destination is used by simulator UUID (name matching failed twice on this machine); M0 includes the domain value types (`Action`, `DueDate`, `ReminderRule`, `Category`) because `TaskRow` needs a real model, `SettingsStore` with minute-of-day storage so M4 planning needs no date math; the design system uses system text styles mapped to the spec's roles (largeTitle ≈32pt, footnote ≈13pt, caption ≈12pt) so Dynamic Type scales natively; capture button and capture sheet have screenshot-verification launch args (`-autopilot-tab-*`, `-autopilot-show-capture`); `Text.kerning` doesn't exist, tracking is applied via `Text.tracking` in the `typeStyle` overload returning `Text`.
- Deleting all data also cancels all pending notifications and deletes the Keychain device token.
- "Deliverable: 5 questions max" — batched below.
