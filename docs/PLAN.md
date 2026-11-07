# AUTOPILOT — Build Plan (Phase A)

One-liner: Tell it what is going on in your life in plain language, and it turns that into organized, scheduled, confirmed actions.

## 1. Final screen list

| # | Screen | Purpose | Notes |
|---|--------|---------|-------|
| 1 | Today | Plan for today, overdue section, briefing card, reminder-off banner | Default tab. Empty state has one primary button: "Tell AUTOPILOT what is happening". |
| 2 | Inbox | All actions, grouped (unsorted first, then by due date), category chip filter, weekly progress strip | No Projects screen. Chips filter, they are not a hierarchy. |
| 3 | Task detail | View/edit/delete a single action, natural-language edit field, reminders | Pushed from Inbox/Today. |
| 4 | Settings | Workday hours, capacity, briefing time, notifications, quiet hours, privacy note, delete all data, paywall entry | No dead toggles — every control persists. |
| 5 | CaptureSheet (sheet) | Text capture (+ voice via Speech framework if ahead of schedule), Parse button | Opens over any tab from persistent bottom-right button. |
| 6 | ConfirmSheet (sheet, stage 2 of capture) | Editable action cards, confidence chips, clarify chips, select/deselect, "Add N actions" | Spring presentation. |
| 7 | Paywall (sheet) | Free limits stated plainly, Pro stub | Debug builds are Pro via `StubEntitlementService`. |

Total: 5 static screens + 3 sheets. Nothing else ships.

## 2. File tree to create

```
Autopilot/
├── App/
│   ├── AutopilotApp.swift          # @main, SwiftData container, environment wiring
│   ├── AppEnvironment.swift        # builds services (stub or live per build flag/setting)
│   └── RootView.swift              # TabView + capture button + toast host
├── DesignSystem/
│   ├── Theme.swift                 # semantic Color/Font/spacing tokens via @Environment
│   ├── Components.swift            # PrimaryButton, SecondaryButton, Chip, SectionHeader
│   ├── TaskRow.swift               # + SkeletonRow, used by Today/Inbox
│   ├── Overlays.swift              # Toast, EmptyState, InlineError, ActionCard, SegmentedFilter
│   └── Haptics.swift               # in Services; thin wrapper here if needed
├── Features/
│   ├── Today/
│   │   ├── TodayView.swift
│   │   ├── TodayViewModel.swift
│   │   └── BriefingCard.swift
│   ├── Inbox/
│   │   ├── InboxView.swift
│   │   ├── InboxViewModel.swift
│   │   ├── WeeklyStrip.swift
│   │   └── TaskDetailView.swift
│   ├── Capture/
│   │   ├── CaptureView.swift
│   │   ├── CaptureViewModel.swift
│   │   ├── ConfirmSheetView.swift
│   │   └── ConfirmViewModel.swift
│   └── Settings/
│       ├── SettingsView.swift
│       ├── SettingsViewModel.swift
│       └── PaywallView.swift
├── Domain/
│   ├── Action.swift                # Action, ActionKind, ActionStatus, Priority
│   ├── DueDate.swift               # DueDate, Precision
│   ├── ReminderRule.swift
│   ├── Category.swift              # fixed list + normalization
│   ├── ExtractionResult.swift      # validated pipeline output + Clarification
│   └── DailyPlan.swift
├── Data/
│   ├── ActionRecord.swift          # @Model
│   ├── SchemaV1.swift              # VersionedSchema + MigrationPlan stub
│   ├── ActionRepository.swift      # only SwiftData touchpoint
│   └── SettingsStore.swift
├── Services/
│   ├── ExtractionService.swift     # protocol + Stub + Live
│   ├── PlanBuilder.swift           # deterministic scheduler (pure)
│   ├── PlanService.swift           # rationale via proxy; template fallback
│   ├── TaskEditService.swift       # protocol + Stub + Live (natural-language edit)
│   ├── NotificationScheduler.swift # caps, quiet hours, stable ids (singleton-permitted)
│   ├── DateResolver.swift          # date clamps, relative helpers
│   ├── Deduplicator.swift          # token-overlap rule from §7
│   ├── EntitlementService.swift    # protocol + StoreKit stub
│   └── Validation.swift            # re-validation of model JSON on arrival
├── ProxyWorker/                    # NOT in the iOS target; deployed separately
│   └── src/index.ts                # Cloudflare Worker, all 4 endpoints
├── Resources/
│   └── Assets.xcassets
└── Tests/
    ├── PlanBuilderTests.swift
    ├── ValidationTests.swift       # schema re-validation, clamps, dedup
    ├── RepositoryTests.swift       # CRUD survives round-trip
    └── HeuristicParserTests.swift  # M2 offline demo sentence

```
Line budget: every file < 250 lines; split by feature as shown.

## 3. Data model

Exactly as in the brief (§6). Confirmed decisions:

- `DueDate` stored on `ActionRecord` as `dueDate: Date?`, `dueTime: Date?`, `duePrecision: String`, `dueIsExplicit: Bool` — four columns so `dueDate` sort/filter predicates work.
- `ActionRecord.id` is `@Attribute(.unique)`.
- `SchemaMigrationPlan` with `Version1` only; migration plan registered but trivial.
- `Settings` persisted in `UserDefaults` via `SettingsStore` (not SwiftData) — small, typed, no relationships.
- Device token in Keychain (kSecClassGenericPassword, accessible after first unlock).
- Free-tier counters (captures today, open actions) computed by repository queries, not stored.

## 4. AI contract

Two stages, per brief §7. Binding summary:

**Stage 1 — local normalize:** trim, collapse whitespace, cap 2000 chars. Attach now/tz/locale/weekday names/5 recent open titles.

**Stage 2 — proxy call:** `POST {baseURL}/v1/extract` (also `/v1/task-edit`, `/v1/plan`, `/health`). Schemas from §8 verbatim, `temperature: 0.2`, 20s timeout, 1 retry on malformed, then 502 → `.invalidResponse`.

**Re-validation on arrival (client, enforced):** required fields, ISO date parse, confidence 0...1, `sourceQuote` substring check, category whitelist, estimate 5...480. Any failure → `.invalidResponse`, retry offered, nothing saved.

**Post-processing (Swift):** past-date clamp (12h, unless input mentions "overdue"/"yesterday"), reminder defaults (24h+1h if due >26h out, else 1h), dedup (token overlap >0.7 + same category + due within 24h → chip + default unchecked).

**Plan:** deterministic PlanBuilder (§8 algorithm, greedy fill, pure and unit-tested in Swift); model writes only the `rationale`. `orderedIds` must be a permutation of candidate ids or the model output is discarded and the template rationale is used.

**Never:** auto-save without the confirm step; client never sees raw model text; keys live only in the Worker.

## 5. Milestone checklist (from §13, with adjustments)

| M | Scope | Extra commitments | DoD gate |
|---|-------|-------------------|----------|
| M0 | Xcode project, 3 tabs, capture button (opens Capture with honest empty state), all base components, empty states | Tokens as code + a checklist row per component wired into a real screen | build+test pass, all screens reachable, zero placeholder copy |
| M1 | SwiftData, repository, fixture seeding (debug flag), Inbox grouping/filters, Task detail edit/delete | WeeklyStrip counts live from repository | CRUD survives relaunch in simulator |
| M2 | Capture offline, heuristic parser (narrow phrase set incl. the demo sentence), confirm sheet, toast+undo | Undo window: toast lifetime 5s | demo sentence → 3 editable cards, airplane mode |
| M3 | Worker proxy (`/v1/extract` first), `ExtractionService.Live`, schema validation, retry/error/clarification states | `/health` used by app on error to distinguish offline vs 5xx | forced 500 → retry state, no crash |
| M4 | PlanBuilder + Today sections, briefing card, notifications with caps/quiet hours | Notification permission requested after first successful capture | plan respects capacity; notification fires at test time in sim |
| M5 | Dynamic Type, dark mode, VoiceOver, haptics, Reduce Motion | Contrast check against token table for both themes | no truncation at XXXL, AA contrast both themes |
| M6 | Stub fallback (airplane mode run), TestFlight-ish archive, demo script, known issues list | Rehearse demo 3× locally | airplane-mode demo works end to end |

## 6. Risk table

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Worker deployment/credentials unavailable at M3 | Med | Med | `ExtractionService.Stub` + offline heuristic parser (M2) keep the whole demo alive; Live ships behind a settings toggle |
| SwiftData iOS 17 quirks (predicate/sort limitations on non-primitive fields) | Med | Med | all `due` data as primitive columns; repository tests round-trip every field; avoid complex compound predicates |
| Heuristic parser overpromises and users expect live-AI behavior offline | Med | Low | parser excludes anything not matching its phrase patterns → clarification, never an invented action |
| Strict-concurrency compile friction (SwiftData + @Observable + network) | Med | Low | services `Sendable`, view models `@MainActor`, network/parsing off main; concurrency headroom budgeted in M0–M2 |
| Strict JSON schema not enforced by actual model output | Med | High | client re-validation is the gate; malformed → typed error + retry; Worker retries once, then 502 |
| Rate limits make live demo fail mid-pitch | Low | High | demo runs on stub path; counters reset daily; `.rateLimited` copy is honest |
| Testing notifications in simulator unreliable | High | Low | debug "Fire test notification in 10s" button in Settings; verified at M4 with a scheduled near-term trigger |
| Scope creep (voice/extensions/sync) demo pressure | High | Med | §2 "Must have" only; "should have" unlocked only if milestone ends early; voice is the first unlock |

## 7. Demo (one screen)

**90 seconds, one device.**

| Beat | On screen | Said or typed |
|------|-----------|--------------|
| 0 | Today, empty state | — |
| 1 | CaptureSheet | type: `Tomorrow I need to email my professor about the exam, Friday I have to pay my internet bill, and next week I need to finish my university project.` → Parse |
| 2 | ConfirmSheet | skeleton → 3 cards; project card has low-confidence chip |
| 3 | ConfirmSheet | "Nothing is saved until I say so." — uncheck project, Add 2 actions |
| 4 | Today | plan + capacity, overdue section explains yesterday's item |
| 5 | TaskDetail | type "move this to Thursday and remind me the day before" → card updates |
| 6 | Inbox/Today | complete one action → toast → weekly strip moves |
| 7 | Settings | briefing line in Today, privacy note |

Offline guarantee: M2 heuristic path produces the same 3-card result in airplane mode.
