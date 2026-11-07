# AGENTS.md — working rules for any agent on this repo

## Stack (fixed, no exceptions)
- Swift 6, SwiftUI, SwiftData, async/await, URLSession. iOS 17.0 minimum.
- No third-party packages. No Combine. No UIKit unless SwiftUI has no equivalent. No storyboards.
- No dependency additions without rewriting this file first.

## Repo rules
- `docs/BRIEF.md` is the product brief. `docs/PLAN.md` is the agreed build plan. New assumptions go in `docs/DECISIONS.md` (one line each), never silently in code.
- One milestone at a time (see PLAN.md §5). Each milestone must: compile, pass tests, and launch in the simulator before reporting.
- Report per milestone: what changed, what is real vs stubbed, what could not be verified.
- Never commit secrets. Keys live only in the Cloudflare Worker (as secrets) and local `.env` files that are gitignored. Never hardcode a model id in app code.
- Files under 250 lines. Split by feature, not by layer. No `Utils.swift` dumps.
- Ambiguity: pick the simplest option that still demos well, record it in DECISIONS.md, move on.

## Build & check (both must pass before "done")
```
xcodebuild -scheme Autopilot -destination 'platform=iOS Simulator,name=iPhone 16' build
xcodebuild -scheme Autopilot -destination 'platform=iOS Simulator,name=iPhone 16' test
```
Never report "done" from a code read alone.

## Code rules
- Strict concurrency on. `@MainActor` for UI mutation; network and parsing off the main actor. Services are `Sendable`.
- Views never touch `@Model` objects; `ActionRepository` is the only SwiftData caller; views see `Action` value types.
- `@Observable` view models, one per screen, injected via `@Environment`. Only `NotificationScheduler` may be process-wide.
- Every service ships a `Stub` with fixtures; the app must demo fully offline.
- Errors are typed enums mapped to human copy. No raw error strings in UI. No `try!`/`fatalError` in shipped paths, no placeholder text, no dead buttons — unfinished surfaces get an honest empty state.
- Colors and type only via DesignSystem tokens, never hardcoded in views.
- AI output is never trusted without client-side re-validation, and never auto-saved without the confirm step.

## Worker
- `ProxyWorker/` is a single-file Cloudflare Worker in TypeScript, deployed separately, excluded from the iOS target. Endpoints: `/v1/extract`, `/v1/task-edit`, `/v1/plan`, `/health`.
