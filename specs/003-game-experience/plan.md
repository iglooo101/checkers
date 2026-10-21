# Implementation Plan: Game Experience

**Branch**: `003-game-experience` | **Date**: 2026-10-21 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/003-game-experience/spec.md`

## Summary

Replace the web-view prototype with a native SwiftUI app: a Home screen, Game setup, a game
screen where two players play American checkers by tapping or dragging, a result panel, undo,
and placeholder Statistics, Rules and Settings screens. A main-actor `@Observable` `GameSession`
wraps the engine's `GameState` and owns the interaction rules (selection, chain lock, "capture
required" notice, drag and drop), so every rule is unit-tested without UI. An `@Observable`
`AppRouter` drives one `NavigationStack` and keeps the session alive while Rules or Settings are
open. Setup choices are remembered through a `SetupStore` protocol backed by `UserDefaults`. The
board is drawn from shapes in the Classic colors with no animation, sized so squares stay at
least 44 points on the narrowest iPhone. Research: [research.md](research.md).

## Technical Context

**Language/Version**: Swift 6.2 (Xcode 26.3), Swift 6 language mode, complete strict concurrency;
the app target's default isolation is the main actor

**Primary Dependencies**: SwiftUI, Observation, OSLog, Foundation (`UserDefaults`, `JSONEncoder`);
`CheckersEngine` (E2, local package); SwiftLintPlugins 0.65.1 (build-time, existing)

**Storage**: One `UserDefaults` value for the last setup choices, behind `SetupStore`

**Testing**: Swift Testing in `checkersTests` for models, layout, navigation and storage; XCUITest
in `checkersUITests` for one flow per story; both in the blocking `checkers.xctestplan`

**Target Platform**: iOS 26.2+, iPhone only, portrait

**Project Type**: mobile app (Xcode project) using the existing local engine package

**Performance Goals**: a move appears within one screen refresh of the input (SC-004, no
animation); cold launch no slower than the 3.6 s local baseline (SC-005)

**Constraints**: no web content; no animations on the board; every string in the String Catalog;
asset-catalog colors with light and dark variants; squares at least 44 points on a 375-point-wide
screen; no test-only code paths in the app

**Scale/Scope**: 4 screens (Home, setup, game, placeholder), about 15 app source files, about
12 unit and UI test files; 42 functional requirements, 7 user stories

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|---|---|---|
| I. Native & Modern Apple Stack | Pass, resolves E1's exception | All UI in SwiftUI; the web view, HTML screens and `UIViewRepresentable` are deleted (FR-006, R13), which removes E1's only Complexity Tracking entry. State uses `@Observable`; no Combine, `ObservableObject` or Dispatch. |
| II. Feature-Based Architecture | Pass | Code grouped as `App/` and `Features/Home`, `Setup`, `Game`, `Placeholders`. Views are thin: interaction rules live in `GameSession`, navigation in `AppRouter`, persistence in `SetupStore` (II.2). `UserDefaults` only behind the injected `SetupStore` protocol with live and in-memory conformances (II.3). Value types except the two `@Observable` models (II.4). No shared abstractions: one placeholder view used three times, one palette for one theme (II.5). |
| III. Test-First Quality | Pass | Each story's unit and UI tests come before its implementation in `tasks.md`; suites and test names carry story and FRD IDs (R12). Swift Testing for models; XCUITest only for UI flows (III.2). Storage tested against an in-memory fake and a private `UserDefaults` suite (III.4). |
| IV. Safety & Correctness | Pass | No force unwraps outside tests. Setup decoding failures are caught, logged and mapped to the defaults; an unexpected engine rejection is logged and changes nothing (IV.2). The only user-reachable error is "capture required", shown with its recovery (choose a capturing piece) (IV.3). Strict concurrency: models are main-actor; engine values are `Sendable`. |
| V. UX & Accessibility | Pass | System components and SF Symbols (crown); asset colors with dark variants (V.1). Dynamic Type to `accessibility5`, Dark Mode, VoiceOver labels on every control and square (V.2, R11). No asynchronous data, so no loading states (V.3). Whole-sentence strings in the String Catalog, no concatenation (V.4, R9). Previews for every view (workflow 4). |
| VI. Privacy & Security | Pass | Only the setup choices are stored, on device. The privacy manifest gains the user-defaults required-reason API (`CA92.1`) in the same change (VI.3, R7). No network, no permissions. |
| VII. Performance | Pass | No background work: engine calls on a tap are tiny (R14). No animation (SC-004). Launch measured with the existing launch test (SC-005). |
| VIII. Simplicity & Dependencies | Pass | No new dependencies. Placeholders and the disabled computer start are the minimum the clarifications require; no computer opponent stand-in (VIII.3). The two engine initializers made public are needed now, by previews (R12). |
| IX. Observability | Pass | `Log` gains `game` and `setup` categories; logged values keep default private redaction. |
| Workflow gates | Pass | spec → clarify → plan → tasks → implement; `main` protected by `CI gate`. |

**Gate result (pre-research)**: PASS. No violations.

### Dependency justification (Principle VIII)

| Dependency | Why Apple frameworks fall short | Maintenance | License | Added via |
|---|---|---|---|---|
| *(none added)* | | | | |

### Lint allow-list

| File | Rule | Reason |
|---|---|---|
| *(none)* | | The allow-list stays empty. |

### Other recorded decisions

- **Saving setup choices on change** (R7): needed because computer games cannot start in this slice;
  E4 keeps it unless its spec says otherwise.
- **First-use defaults** are Two players, Easy, Light until E4 switches to the FRD's Computer, Easy,
  Light (Clarifications).
- **String catalog**: `scripts/sync-string-catalog.sh` updates the catalog after command-line
  builds (R9); the old picker strings are removed with the web screens.
- **Engine API change**: `Position.init(_:)` and `GameState.init(position:sideToMove:)` become
  public (T002), because previews in the app target need constructed positions (a king, a
  capture, a chain) and can use only public API (R12). Behavior is unchanged; the engine contract
  records it.

### Post-design re-check

Re-evaluated after Phase 1 ([data-model.md](data-model.md), [contracts/](contracts/),
[quickstart.md](quickstart.md)): no new violations. The design keeps all rules in the engine and
all interaction rules in one tested model; views hold no logic beyond layout and gestures; the
only storage is behind a protocol and declared in the privacy manifest.
**Gate result (post-design)**: PASS.

## Project Structure

### Documentation (this feature)

```text
specs/003-game-experience/
├── plan.md              # This file
├── research.md          # Phase 0 decisions R1–R14
├── data-model.md        # Setup, layout, session, router, store
├── quickstart.md        # Validation scenarios per story and success criterion
├── contracts/
│   ├── game-session.md  # Tap, drag, step, undo, resign and navigation rules
│   └── screens.md       # Screens, exact texts, accessibility identifiers, layout rules
├── checklists/
│   ├── requirements.md  # Spec quality checklist
│   └── validation.md    # Quickstart results (written during implementation)
└── tasks.md             # Phase 2 output (/speckit-tasks)
```

### Source Code (repository root)

```text
checkers/checkers/                         # app target (synchronized group)
├── CheckersApp.swift                      # scene: RootView with the live router and store
├── App/
│   ├── Route.swift                        # setup, game, statistics, rules, settings
│   ├── AppRouter.swift                    # @Observable: path, session, setup, leave confirmation
│   └── RootView.swift                     # NavigationStack over Home
├── Features/
│   ├── Home/HomeView.swift
│   ├── Setup/
│   │   ├── GameSetup.swift                # Opponent, Difficulty, SideChoice, defaults, canStart
│   │   ├── SetupStore.swift               # protocol, UserDefaultsSetupStore, InMemorySetupStore
│   │   └── SetupView.swift
│   ├── Game/
│   │   ├── GameSession.swift              # @Observable interaction rules over GameState
│   │   ├── GameText.swift                 # turn, result, notice and square-label sentences
│   │   ├── BoardLayout.swift              # display cell ↔ square, both orientations
│   │   ├── GameView.swift                 # indicator, notice, board, menu, dialogs, result
│   │   ├── BoardView.swift                # 8×8 squares, tap and drag
│   │   ├── PieceView.swift                # man, king (crown), selection and hint rings
│   │   └── ResultPanel.swift
│   └── Placeholders/
│       ├── PlaceholderView.swift          # title and one line; used for three screens
│       └── PlaceholderText.swift          # the three one-line messages
├── Support/
│   ├── Logging.swift                      # + game and setup categories
│   └── Palette.swift                      # asset-catalog colors of the Classic board
├── Assets.xcassets/                       # + Board and piece color sets (light and dark)
├── Localizable.xcstrings                  # new strings; picker strings removed
└── PrivacyInfo.xcprivacy                  # + user defaults, CA92.1
checkers/checkersTests/
├── Support/GamePositions.swift            # positions through the engine's public initializers
├── GamePositionsTests.swift
├── US1TwoPlayerMoveTests.swift, US2CaptureChainTests.swift, US3HintsDragTests.swift,
│   US4GameEndTests.swift, US5GameUndoTests.swift, US6SetupTests.swift (incl. the stores),
│   US7NavigationTests.swift               # session, router and setup rules by story
├── BoardLayoutTests.swift
├── PaletteTests.swift                     # every board color resolves (FR-GAME-07)
├── NoWebContentTests.swift                # replaces ScreenCatalogTests (FR-006)
├── PrivacyManifestTests.swift             # updated: exactly the user-defaults entry
├── LocalizationTests.swift                # updated: the new strings
└── EngineLinkTests.swift, LoggingTests.swift, PlatformSettingsTests.swift   # existing
checkers/checkersUITests/
├── Support/AppScreens.swift               # identifiers and helpers (tap square by name)
├── US1TwoPlayerMoveUITests.swift, US2CaptureUITests.swift, US3DragUITests.swift,
│   US4GameEndUITests.swift, US5UndoUITests.swift, US6SetupUITests.swift,
│   US7NavigationUITests.swift
└── LaunchPerformanceTests.swift           # existing
scripts/sync-string-catalog.sh             # update the catalog after command-line builds
```

Deleted: `checkers/checkers/ContentView.swift`, `Classic.html`, `Modern.html`, `Playful.html`,
`Play.html`, `move.wav`, `checkers/checkersTests/ScreenCatalogTests.swift`,
`checkers/checkersUITests/AppSmokeUITests.swift`.

**Structure Decision**: Organize the app target by feature as the constitution asks, now that it
has real features; keep the session in the app target (one feature uses it) and the rules in the
engine package. The synchronized group means files are added and removed without project edits.
Scripts stay at the repository root.

## Complexity Tracking

No violations to justify. E1's entry (web content, Principle I.1) is resolved by this slice.

## Follow-ups for other slices

- **E4 (#107, #109)**: add the computer's turn to `GameSession` (input locked, thinking indicator,
  computer moves first as Light), enable Start for Computer, switch the first-use defaults to the
  FRD's, and remove the setup note. Decide whether setup keeps saving choices on change or saves
  them when a game starts, as FR-SETUP-03's "used in the previous game" reads (R7).
- **E5 (#122–#127, #189, #72)**: replace the leave confirmation with saving and Continue; add
  "Abandon current game?".
- **E6 (#141, #145, #150)**: replace the Settings and Rules placeholders; themes extend `Palette`
  (three themes then justify a theme type); the hints toggle feeds `GameSession`'s hint rule.
- **E7 (#161–#168)**: extend square labels with states, add square-by-square VoiceOver play,
  announcements from `StepResult`, and the accessibility audit test on every screen.
