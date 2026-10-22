# Implementation Plan: Computer Opponent

**Branch**: `005-computer-opponent` | **Date**: 2026-10-22 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/005-computer-opponent/spec.md`

## Summary

Add the computer opponent on top of the rules engine (E2), the game screen (E3) and the VoiceOver
board (E7). The engine gains `ComputerPlayer`, an alpha-beta search over complete turns with
iterative deepening, at three `ComputerLevel`s set by depth, node limit and a random margin. It
is pure and repeatable from a seed. Profiling showed the engine's step generation spends most of
its time allocating arrays, so the search uses its own allocation-free turn generator. A
prototype of it is about 140 times faster in Release. `GameState` stays the referee: root turns
come from it and every computer step is applied through it. `GameSession` plays the computer's
turn as a cancellable task through two injected seams, a `ComputerOpponent` (the live one
searches off the main actor with a 0.8 s limit) and a `TurnPacer` (0.5 s minimum and 0.5 s
between jumps). The board is locked meanwhile, each step is announced, steps are held while Rules
or Settings is open, and Undo uses one rule that returns to the player's turn. Setup can start
computer games, with the FRD's defaults. Strength is proven by 100-game matches between the
levels, run in Release in a new parallel CI job. Research: [research.md](research.md).

## Technical Context

**Language/Version**: Swift 6.2 (Xcode 26.3), Swift 6 language mode, complete strict concurrency;
app target default isolation is the main actor with approachable concurrency; the engine package
is nonisolated

**Primary Dependencies**: SwiftUI, Observation, Swift Concurrency (`@concurrent`, `Task`,
cancellation), `CheckersEngine` (E2); SwiftLintPlugins (build-time, existing)

**Storage**: N/A (the setup choices keep E3's `UserDefaults` store; only when they are saved
changes)

**Testing**: Swift Testing for the engine (turn generator, search, levels) and the app (computer
turn, undo, announcements, setup); a Release-only engine test target for the strength matches;
XCUITest for a computer game and the audit; a playtest and an iPhone timing by hand (SC-004,
SC-005)

**Target Platform**: iOS 26.2+, iPhone only, portrait; engine tests also on macOS 15+

**Project Type**: mobile app (Xcode project) with the local engine package

**Performance Goals**: first computer step 0.5–1 s after its turn starts (FR-008); Hard's slowest
turn in the matches at most 0.5 s on the development Mac in Release; the main actor never runs the
search; turn generation for the search at least 10 million turns per second in Release on the
development Mac (prototype: 25 million, *measured*)

**Constraints**: every computer step goes through `GameState.apply`; the engine has no clocks and
no randomness except from the seed it is given; whole sentences from the String Catalog; no
test-only behavior in the app; the strength job finishes in under 15 minutes on CI

**Scale/Scope**: about 6 new engine files, 2 new and 7 changed app files, a new engine test
target, a CI job; 28 functional requirements, 5 user stories

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|---|---|---|
| I. Native & Modern Apple Stack | Pass | SwiftUI and `@Observable`; the computer's turn is a `Task` with structured cancellation and the search runs in a `@concurrent` function (R7); no Dispatch, Combine or threads. |
| II. Feature-Based Architecture | Pass | The search is UI-free logic in the engine package; the turn, undo and announcement rules live in `GameSession`, navigation effects in `AppRouter`; views only show the thinking header. `ComputerOpponent` and `TurnPacer` are injected protocols with live and fake conformances (II.3, exempt from II.5). Engine types are structs and enums. |
| III. Test-First Quality | Pass | Each story's tests come before its code; the timeline is tested without waiting through the manual pacer; strength is proven by matches that block CI (III.5) in their own job; acceptance tests name US1–US5. |
| IV. Safety & Correctness | Pass | No force unwraps; the only failure, the opponent returning no turn, is logged and handled by playing the first legal turn; cancellation is handled explicitly, never by `try?`. No `@unchecked Sendable` or `nonisolated(unsafe)`. |
| V. UX & Accessibility | Pass | The thinking header is a catalog sentence in primary text with a system activity indicator; VoiceOver announces the computer's steps and keeps focus; previews at accessibility5 and in Dark Mode; audited states updated (R12). |
| VI. Privacy & Security | Pass | No new data; the setup keeps its declared `UserDefaults` use (CA92.1). |
| VII. Performance | Pass | The search runs off the main actor (VII.3); the design rests on a Time Profiler trace and measured benchmarks (VII.4, research environment facts); Hard's node limit is set by measurement. |
| VIII. Simplicity & Dependencies | Pass | No dependencies. The second turn generator is justified by measurement (R1); no transposition table or opening book until a measured need. |
| IX. Observability | Pass | New `Log.computer` category with one debug line per turn; no personal data (R14). |
| Workflow gates | Pass | spec → clarify → plan → tasks → implement. |

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
| Game setup, Computer chosen | Start while disabled | | **Removed**: Start is available for computer games. |
| Game setup | A static text line, or Start (`setup.start`), that the scrolling form cuts at the screen's edge | Dynamic Type, "partially unsupported" only | E7's entry, widened in US1 to Start: with Computer chosen the form is longer and Start is the row at the bottom edge when the audit enlarges the text. It scales and scrolls into view (checked on screen at the largest size in E7). |

### Other recorded decisions

- **Spec alignment**: FR-027 audited "the game screen during the computer's turn". That state
  lasts under a second, shorter than an audit run, so the audit covers a computer game on the
  player's turn and with the result panel. The thinking header is checked by unit tests while
  the computer thinks and by previews (R12). The spec is updated to match.
- **Two turn generators**: `GameState` (single steps, for the screen and as the referee) and the
  search's `TurnGenerator` (complete turns, allocation-free). The generator is held to
  `GameState` by the published counts and a 1,000-position cross-check (R1).
- **CI**: a new `engine-strength` job (macOS, `swift test -c release` for the strength target)
  runs in parallel with `build-and-test`; `scripts/ci/gate.sh`, its script test and
  `specs/001-project-foundation/contracts/ci-gate.md` change so `CI gate` requires both on code
  pushes.
- **Engine contract**: `specs/002-rules-engine/contracts/engine-api.md` gets a pointer to
  [contracts/computer-player.md](contracts/computer-player.md); no existing API changes.
- **E3 tests that change**: setup defaults and the "cannot start" rule (`US6SetupTests`,
  `US6SetupUITests`) are rewritten test-first for FR-001 to FR-003.

### Post-design re-check

Re-evaluated after Phase 1 ([data-model.md](data-model.md),
[contracts/computer-player.md](contracts/computer-player.md),
[contracts/computer-turn.md](contracts/computer-turn.md), [quickstart.md](quickstart.md)): no
violations. The design adds two injected seams with live and fake conformances, an engine API that
is pure apart from a stop closure, and a second generator justified by measurement and checked
against the referee. **Gate result (post-design)**: PASS.

## Project Structure

### Documentation (this feature)

```text
specs/005-computer-opponent/
├── plan.md              # This file
├── research.md          # Phase 0 decisions R1–R14, with measurements
├── data-model.md        # Engine and app types
├── quickstart.md        # Validation scenarios
├── contracts/
│   ├── computer-player.md  # Engine API, levels, strength matches
│   └── computer-turn.md    # Timeline, cancelling, input, undo, announcements, texts, router
├── checklists/
│   ├── requirements.md  # Spec quality checklist
│   └── validation.md    # Quickstart results (written during implementation)
└── tasks.md             # Phase 2 output (/speckit-tasks)
```

### Source Code (repository root)

```text
checkers/CheckersEngine/
├── Package.swift                         # + test target CheckersEngineStrengthTests
├── Sources/CheckersEngine/
│   ├── ComputerLevel.swift               # new: levels and their parameters (R4)
│   ├── ComputerPlayer.swift              # new: chooseTurn, ComputerTurn, root turns via GameState
│   ├── Search.swift                      # new: alpha-beta, iterative deepening, draws, stop (R2)
│   ├── Evaluation.swift                  # new: evaluation (R3)
│   ├── TurnGenerator.swift               # new: Board and allocation-free complete turns (R1)
│   └── SeededGenerator.swift             # new: SplitMix64 (R5)
├── Tests/CheckersEngineTests/
│   ├── TurnGeneratorTests.swift          # counts 1–7, cross-check with GameState
│   ├── US1ComputerPlayerTests.swift      # legal turns, first move, chains, endings
│   └── US2ComputerLevelTests.swift       # tactics per level, determinism, limits, self-play
└── Tests/CheckersEngineStrengthTests/
    └── US2StrengthMatchTests.swift       # matches and counts 1–9 (Release, CI job)
checkers/checkers/
├── Features/Game/
│   ├── ComputerOpponent.swift            # new: protocol, EngineComputerOpponent, ScriptedComputerOpponent
│   ├── TurnPacer.swift                   # new: protocol, SleepingPacer
│   ├── GameSession.swift                 # computer turn, phases, covered, undo rule, input lock
│   ├── GameText.swift                    # thinking sentences, computer follow-up
│   └── GameView.swift                    # thinking header with activity indicator
├── Features/Setup/
│   ├── GameSetup.swift                   # defaults, no canStart, Difficulty.computerLevel
│   └── SetupView.swift                   # no note, Start always available
├── App/AppRouter.swift                   # save on start, start turns, covered, cancel on leave
├── Support/Logging.swift                 # + computer category
└── Localizable.xcstrings                 # + thinking sentences, − setup note
checkers/checkersTests/
├── Support/ManualPacer.swift             # records pauses, resumes on demand
├── US1ComputerGameTests.swift            # timeline, input lock, chains, first move, Play again
├── US3ComputerControlTests.swift         # menu actions, resign, leave, covered, main actor free
├── US4ComputerUndoTests.swift            # undo rule and availability
├── US5ComputerAnnouncementTests.swift    # announcements and focus
└── US6SetupTests.swift                   # changed: defaults, start, remembered on start
checkers/checkersUITests/
├── US1ComputerGameUITests.swift          # start, thinking header, reply, undo (Easy)
├── US5AccessibilityAuditUITests.swift    # changed: audited states (R12)
└── US6SetupUITests.swift                 # changed: Start for Computer
.github/workflows/ci.yml                  # + engine-strength job
scripts/ci/gate.sh, scripts/tests/test-ci-gate.sh   # gate requires both jobs
```

**Structure Decision**: The search joins the rules in `CheckersEngine` (UI-free, testable on the
Mac); the turn's interaction rules join `GameSession` next to the player's; the two seams sit
beside the session that uses them, as the announcer does.

## Complexity Tracking

No violations to justify.

## Follow-ups for other slices

- **E5 (#125)**: a game saved during the computer's turn resumes with
  `startComputerTurnIfNeeded()` (FR-SAVE-04); saving happens between turns, so never mid-chain.
- **E5 (#129)**: record results against the computer by `Difficulty`; undo does not change it
  (FR-UNDO-08).
- **E6 (#147, #148)**: sounds for the computer's steps as for the player's.
- **E8 (#182)**: the hitch check covers computer turns; signposts may wrap the search then.
