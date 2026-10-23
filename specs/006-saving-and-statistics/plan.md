# Implementation Plan: Saving and Statistics

**Branch**: `006-saving-and-statistics` | **Date**: 2026-10-22 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/006-saving-and-statistics/spec.md`

## Summary

Keep the game in play and a record of games against the computer, on top of the rules engine
(E2), the game screen (E3), the VoiceOver board (E7) and the computer opponent (E4). The engine's
`GameState` becomes `Codable` with explicit keys and validation, so a saved game holds the exact
state, undo history and draw counters included, and damaged data is rejected. The app stores one
saved game and one record as JSON in `UserDefaults`, behind protocols with in-memory fakes, like
E3's setup store; a 220-turn game is about 23 KB and codes in about 2 ms (*measured*).
`GameSession` reports save points (after every turn and undo, and once when the game ends) and
offers a snapshot that, during the computer's turn, is the state at the start of that turn. The
router saves on those points, when the player leaves and when the app moves to the background;
clears the save and records the result when a game ends; asks "Abandon current game?" before
replacing a saved game; and reports an unreadable save or record once on Home, one alert after the
other. Home gains Continue; leaving
a game no longer asks. A new Statistics screen shows wins, losses and draws per difficulty, with an
empty state. Research: [research.md](research.md).

## Technical Context

**Language/Version**: Swift 6.2 (Xcode 26.3), Swift 6 language mode, complete strict concurrency;
app target default isolation is the main actor with approachable concurrency; the engine package
is nonisolated

**Primary Dependencies**: SwiftUI, Observation, Foundation (`JSONEncoder`, `JSONDecoder`,
`UserDefaults`), `CheckersEngine` (E2, E4); SwiftLintPlugins (build-time, existing)

**Storage**: `UserDefaults.standard`, two new JSON values (`savedGame`, `record`) beside E3's
`lastGameSetup` (R2)

**Testing**: Swift Testing for the engine (coding, validation, a version 1 fixture) and the app
(save points, Continue, abandon, unreadable save and record, record; in-memory stores, scripted
opponent, manual pacer; the `UserDefaults` stores against a temporary suite, with version 1
fixtures); XCUITest for Continue after a relaunch and after the background, the abandon question,
the two restore alerts, Statistics and the audit, with saved data set through launch arguments
(R10)

**Target Platform**: iOS 26.2+, iPhone only, portrait; engine tests also on macOS 15+

**Project Type**: mobile app (Xcode project) with the local engine package

**Performance Goals**: saving never delays the game (SC-006: under 100 ms; measured 2 ms to encode
a 220-turn game and microseconds to write it); Continue shows the game within 1 second (SC-002)

**Constraints**: data stays on the device; at most one saved game; no test-only behavior in the
app; whole sentences from the String Catalog, with plural variants for the counts; previews never
touch storage (workflow gate 4)

**Scale/Scope**: 2 changed engine files and 1 new one, about 6 new and 8 changed app files, 4 user
stories, 26 functional requirements

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|---|---|---|
| I. Native & Modern Apple Stack | Pass | SwiftUI and `@Observable`; Foundation's JSON coding and `UserDefaults`; the scene phase from SwiftUI; no Combine, Dispatch or threads. |
| II. Feature-Based Architecture | Pass | Saving (`SavedGame`, its store) and Statistics (`Record`, its store, `StatisticsView`) are features of their own; the rules of when to save and what to record live in `GameSession` and `AppRouter`, not in views; the stores are injected protocols with live and in-memory conformances (II.3, exempt from II.5), wrapping `UserDefaults.standard` (II.3). New types are structs and enums except the stores, which keep state. |
| III. Test-First Quality | Pass | Each story's tests come first; app logic is tested against the in-memory stores (III.4), the `UserDefaults` stores against a temporary suite; acceptance tests name US1–US4; UI tests get their data through launch arguments, not app switches (R10). |
| IV. Safety & Correctness | Pass | Typed `SavedGameError` and `RecordError` for the stores (IV.2); every decoding and encoding failure is logged and handled; both failures the player can see are shown on Home with OK (IV.3): an unreadable save (alert, no Continue) and an unreadable record (alert, zero; FR-STAT-06, added after `/speckit-analyze` found the first design reset it silently); a write failure keeps the old value; no `try?` that hides a user-visible failure; no force unwraps. |
| V. UX & Accessibility | Pass | Continue, the alerts and Statistics in primary text, with VoiceOver labels and plural sentences from the String Catalog; previews at accessibility5 and in Dark Mode; the empty state is explicit (V.3); new audited states (contracts/screens.md). |
| VI. Privacy & Security | Pass | Only game data, on the device (FR-024); `UserDefaults` is already declared with reason CA92.1, so the privacy manifest does not change (R13); no permissions, no network. |
| VII. Performance | Pass | Saving and coding measured before the design (R2, environment facts); the writes are microseconds, so no file I/O runs on the main actor (VII.3). |
| VIII. Simplicity & Dependencies | Pass | No dependencies; `UserDefaults` instead of SwiftData or files for two small values (R2); no format migration until a second version exists. |
| IX. Observability | Pass | New `Log.storage` category for read and write failures, without game data (R12). |
| Workflow gates | Pass | spec → clarify → plan → tasks → implement; every new view has previews with in-memory data. |

**Gate result (pre-research)**: PASS. No violations.

### Dependency justification (Principle VIII)

| Dependency | Why Apple frameworks fall short | Maintenance | License | Added via |
|---|---|---|---|---|
| *(none added)* | | | | |

### Lint allow-list

| File | Rule | Reason |
|---|---|---|
| *(none)* | | The allow-list stays empty. |

### Audit allow-list

| Screen | Element | Issue type | Reason |
|---|---|---|---|
| Game setup | A static text line, or Start (`setup.start`), that the scrolling form cuts at the screen's edge | Dynamic Type, "partially unsupported" only | Unchanged from E4. |
| Setup and Home, while a system alert shows (the abandon question, the two restore notices) | A static text of the alert (title or message), or an element the audit does not name | Dynamic Type, "partially unsupported" only | Added by T024. The alerts are system alerts: on screen at the largest accessibility size their title, message and buttons grow several times (screenshot check), but the audit reports their labels as partially unsupported, some runs without naming the element. The app cannot style a system alert's labels. Allowed issues are logged in the test report. |

New screens add no entries; if their audits report a system component, the entry is added here
with its reason.

### Other recorded decisions

- **Spec alignment**: FR-010 removes E3's leave confirmation (E3's FR-042); E3's
  `specs/003-game-experience/contracts/screens.md` keeps its history, and this slice's screens
  contract records the removal.
- **Engine contract**: `specs/002-rules-engine/contracts/engine-api.md` gets a pointer to
  [contracts/saved-game.md](contracts/saved-game.md) for `GameState`'s coding; no other API
  changes.
- **E3 and E4 tests that change** (completed by `/speckit-analyze`): the leave-confirmation tests
  (`leaveConfirmation` in `US7NavigationTests`, `leaveWhileThinking` and `menuWhileThinking` in
  `US3ComputerControlTests`, `testUS7_leaveConfirmation` in `US7NavigationUITests`) are rewritten
  first for leaving without a question (US1); the tests of the Statistics placeholder
  (`placeholderMessages`, `testUS7_placeholdersFromHome`, `testUS5_auditStatistics`) change with
  the Statistics screen (US3); the UI start helpers, and the two tests that tap Start directly
  (`US6SetupUITests`, `testUS7_largestTextSize`), answer the abandon question (US2).
- **Launch arguments are checked first**: T001 confirms in the simulator, with E3's existing
  `lastGameSetup` key, that a `-key <hex bytes>` launch argument sets stored data and that a text
  value reads as no data (R10), before any story relies on it.

### Post-design re-check

Re-evaluated after Phase 1 ([data-model.md](data-model.md),
[contracts/saved-game.md](contracts/saved-game.md), [contracts/screens.md](contracts/screens.md),
[quickstart.md](quickstart.md)): no violations. The design adds two injected stores with live and
in-memory conformances, one engine conformance with validation, a session callback and router
state; views stay thin. **Gate result (post-design)**: PASS.

## Project Structure

### Documentation (this feature)

```text
specs/006-saving-and-statistics/
├── plan.md              # This file
├── research.md          # Phase 0 decisions R1–R14, with measurements
├── data-model.md        # Engine and app types
├── quickstart.md        # Validation scenarios
├── contracts/
│   ├── saved-game.md    # Format, validity, stores, save points, recording
│   └── screens.md       # Home, setup alert, game, Statistics, audit
├── checklists/
│   ├── requirements.md  # Spec quality checklist
│   └── validation.md    # Quickstart results (written during implementation)
└── tasks.md             # Phase 2 output (/speckit-tasks)
```

### Source Code (repository root)

```text
checkers/CheckersEngine/
├── Sources/CheckersEngine/
│   ├── GameState+Coding.swift            # new: Codable with explicit keys and validation (R1)
│   ├── GameState.swift                   # internal initializer that decoding needs
│   └── Side.swift                        # Codable as "light"/"dark"
└── Tests/CheckersEngineTests/
    └── GameStateCodingTests.swift        # round trips, validation, version 1 fixture (inline JSON)
checkers/checkers/
├── Features/Saving/
│   ├── SavedGame.swift                   # new: SavedGame, SavedGameError
│   └── SavedGameStore.swift              # new: protocol, UserDefaults and in-memory stores
├── Features/Statistics/
│   ├── Record.swift                      # new: Record, Tally, GameResult, RecordError
│   ├── RecordStore.swift                 # new: protocol, UserDefaults and in-memory stores
│   ├── StatisticsText.swift              # new: block sentences and VoiceOver labels
│   └── StatisticsView.swift              # new: blocks per difficulty, empty state
├── Features/Game/
│   ├── GameSession.swift                 # snapshot, result, events, init(saved:)
│   └── GameView.swift                    # leave alert removed
├── Features/Home/HomeView.swift          # Continue, the two restore alerts
├── Features/Setup/SetupView.swift        # abandon alert
├── Features/Placeholders/                # Statistics entry removed
├── App/AppRouter.swift                   # stores, save points, Continue, abandon, record
├── App/RootView.swift                    # Statistics destination
├── CheckersApp.swift                     # live stores, save on background
├── Support/Logging.swift                 # + storage category
└── Localizable.xcstrings                 # + Continue, alerts, Statistics (plurals); − leave alert, placeholder line
checkers/checkersTests/
├── US1ContinueTests.swift                # save points, snapshot, Continue, leave, background
├── US2AbandonTests.swift                 # abandon question, end clears the save, Play again
├── US3RecordTests.swift                  # recording every ending once; Statistics text
├── US4RestoreFailureTests.swift          # unreadable save and record
├── StorageTests.swift                    # UserDefaults stores against a temporary suite
├── PrivacyManifestTests.swift            # changed: names FR-PRIV-01
├── US7NavigationTests.swift              # changed: leaving without a question; no Statistics placeholder
└── US3ComputerControlTests.swift         # changed: leaving without a question
checkers/checkersUITests/
├── Support/AppScreens.swift              # start helpers and tapStart() answer the abandon question
├── US1ContinueUITests.swift              # Continue after a relaunch; a chain saved in the background
├── US2AbandonUITests.swift               # the abandon question
├── US3StatisticsUITests.swift            # a finished game counts
├── US4RestoreFailureUITests.swift        # a damaged save and a damaged record (launch arguments)
├── US6SetupUITests.swift                 # changed: Start through tapStart()
├── US7NavigationUITests.swift            # changed: Home keeps the game; Rules placeholder; tapStart()
└── US5AccessibilityAuditUITests.swift    # changed: Home with and without Continue, Statistics empty and with a record, the alerts
```

**Structure Decision**: Saving and Statistics each get a feature folder for their types and
stores (Constitution II.1); the rules that tie them to play stay in `GameSession` and `AppRouter`,
which already own the game and the setup store. The engine only learns to encode its own state.

## Complexity Tracking

No violations to justify.

## Follow-ups for other slices

- **E6 (#140)**: Settings choices can use the same store pattern (protocol, `UserDefaults`,
  in-memory).
- **E8 (#192)**: MetricKit can report the `storage` errors logged here.
