# Implementation Plan: Rules Engine

**Branch**: `002-rules-engine` | **Date**: 2026-10-21 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/002-rules-engine/spec.md`

## Summary

Build the complete American checkers rules (FRD sections 8–10, FR-SETUP-06 and the chain behavior
of section 7.3) as UI-free, test-first value types in the existing `CheckersEngine` package. A
`GameState` struct holds the position (three 32-bit sets for Light, Dark and kings), the side to
move, any unfinished chain, the no-progress count, the outcome and an undo history of turn-start
records that doubles as the repetition record. Screens apply one `Step` (from, to) at a time and
get a `StepResult` back; illegal actions throw a typed `RuleError` and change nothing. Correctness
is proven by story-by-story acceptance tests, the published perft counts (OEIS A133046, depths
1–7, independently reproduced to depth 9) and 1,000 seeded random games with full undo.
Research: [research.md](research.md).

## Technical Context

**Language/Version**: Swift 6.2 (Xcode 26.3), Swift 6 language mode, complete strict concurrency

**Primary Dependencies**: Swift standard library only; SwiftLintPlugins 0.65.1 (build-time,
existing)

**Storage**: N/A (all state is in memory in `GameState`; saving is E5)

**Testing**: Swift Testing in `CheckersEngineTests`, run with `swift test` on the Mac and in the
blocking `checkers.xctestplan` on the iPhone simulator

**Target Platform**: iOS 26.2+ (shipped in the iPhone app); macOS 15 for host tests

**Project Type**: local Swift package (library) inside the iPhone app's Xcode project

**Performance Goals**: the 6-turn reference count (36,768 sequences) in under 10 s on the
development Mac (SC-004); the whole engine suite in under 60 s with `swift test` (R12)

**Constraints**: no UI framework imports; no I/O, logging, clocks or randomness in the engine;
every public type `Sendable` and usable off the main actor; no force unwraps; typed throws at the
module boundary; deterministic results and step order

**Scale/Scope**: 10 source files and 12 test files; 27 functional requirements, 5 user
stories, 21 FRD requirement IDs to cover (SC-001)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|---|---|---|
| I. Native & Modern Apple Stack | Pass | No UI in this slice. No `ObservableObject`, Combine, `DispatchQueue`, `OperationQueue` or `Thread`; the engine is synchronous and needs no concurrency primitives. Swift Testing is first-party. |
| II. Feature-Based Architecture | Pass | The rules live in their own package (II.1), used by E3, E4 and E5. All types are structs and enums (II.4). Lookup tables are immutable `static let` constants, not stateful singletons (II.3). No protocols or shared abstraction layers: one rule set, one implementation (II.5). |
| III. Test-First Quality | Pass | Tasks put each story's tests before its implementation, and tests must be seen failing first. Every story has acceptance tests whose suite and display names carry the story ID; display names also list the FRD IDs they prove (R10). No network or persistence. CI blocks on failures, warnings and lint errors (E1). |
| IV. Safety & Correctness | Pass | Failable `Square` creation and table lookups returning optionals avoid force unwraps (IV.1). One typed error enum, `RuleError`, with typed throws on `apply`, `resign` and `undo`; rejected calls change nothing (IV.2). Rejections reach players only through E3, which shows them (IV.3). Explicit `Sendable` on every public type; no `@unchecked Sendable` or `nonisolated(unsafe)` (IV.4). |
| V. UX & Accessibility | Pass | No screens. The engine has no user-facing text: it returns structured values (`StepResult`, `Outcome`, `RuleError`) that E3 and E7 turn into localized strings (V.4). `Square.name` is board notation, not prose. |
| VI. Privacy & Security | Pass | No data collected, no storage, no network, no required-reason APIs. |
| VII. Performance | Pass | All engine types are nonisolated `Sendable` values, so E4 can search off the main actor (VII.3). The SC-004 budget is backed by a measurement (Python prototype: 0.2 s for depth 6 on the development Mac, R1) and is checked by a timing test on every run (VII.4). No optimization beyond a compact representation chosen for value semantics (R2). |
| VIII. Simplicity & Dependencies | Pass | No new dependencies. Only what the spec needs is public; constructed positions, counters and position-level generation stay internal for tests (R9). No `Codable`, search helpers or rule variants (VIII.3). |
| IX. Observability | Pass | The engine does not log: every failure is returned as a typed error for the caller to handle and log. No `print`. |
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

The engine's test folder gets a nested `.swiftlint.yml` relaxing the force-unwrap family and
`no_print`, identical to the app's test targets. This applies Constitution IV.1 ("outside test
targets") and the E1 lint contract ("a nested configuration in each test directory"); it is not
an allow-list exception.

### Other recorded decisions

- **Reference counts** (SC-002): OEIS A133046 and Aart Bik's checkers page, depths 1–7 in the
  blocking suite; depth 7 is the first that includes crowning (R1).
- **Spec alignment**: SC-003 now undoes from the start of each game's final turn, because FR-024
  forbids undo after the game has ended (R11).
- **Existing test name**: `SideTests` keeps its E1 display name, where "US4" means E1's
  engine-package story. `swift test --filter` matches type names, so `--filter US4` runs only
  this slice's `US4EndingTests`.

### Post-design re-check

Re-evaluated after Phase 1 ([data-model.md](data-model.md),
[contracts/engine-api.md](contracts/engine-api.md), [quickstart.md](quickstart.md)): no new
violations. The design adds one internal type (`TurnRecord`) and keeps every public type a
`Sendable` value; the API exposes only what E3–E5 and the tests need. One spec change came out
of the design: SC-003's undo check starts before each game's final turn (FR-024).
**Gate result (post-design)**: PASS.

## Project Structure

### Documentation (this feature)

```text
specs/002-rules-engine/
├── plan.md              # This file
├── research.md          # Phase 0 decisions R1–R12
├── data-model.md        # Engine types, invariants and state transitions
├── quickstart.md        # Validation scenarios per story and success criterion
├── contracts/
│   └── engine-api.md    # Public API, query and rejection rules, guarantees
├── checklists/
│   ├── requirements.md  # Spec quality checklist
│   └── validation.md    # Quickstart results (written during implementation)
└── tasks.md             # Phase 2 output (/speckit-tasks)
```

### Source Code (repository root)

```text
checkers/CheckersEngine/
├── Package.swift                         # unchanged
├── Sources/CheckersEngine/
│   ├── Side.swift                        # existing; + forward direction and far row (internal)
│   ├── Piece.swift                       # PieceKind, Piece
│   ├── Square.swift                      # Square, names, Square.all
│   ├── BoardGeometry.swift               # neighbor and landing tables per square and direction (internal)
│   ├── Position.swift                    # three 32-bit sets, start position, piece(at:)
│   ├── Position+Steps.swift              # legal steps of a bare position (internal)
│   ├── Step.swift                        # Step, StepResult
│   ├── Outcome.swift                     # Outcome, WinReason, DrawReason
│   ├── RuleError.swift                   # RuleError
│   └── GameState.swift                   # GameState, TurnRecord, apply, resign, undo
└── Tests/
    ├── .swiftlint.yml                    # new: relaxes force unwraps and no_print in tests
    └── CheckersEngineTests/
        ├── SideTests.swift               # existing
        ├── Support/
        │   ├── PositionBuilder.swift     # positions from square names; board diagrams in failures
        │   ├── SeededGenerator.swift     # SplitMix64 RandomNumberGenerator
        │   └── TurnCounter.swift         # complete-turn counting for SC-002
        ├── SquareTests.swift             # coordinates, names, validation
        ├── US1StartAndMoveTests.swift
        ├── US2CaptureAndKingTests.swift
        ├── US3ChainAndCrowningTests.swift
        ├── US4EndingTests.swift
        ├── US5UndoTests.swift
        ├── ReferenceCountTests.swift     # SC-002, SC-004
        └── RandomGameTests.swift         # SC-003
```

**Structure Decision**: Everything stays inside the existing `CheckersEngine` package, which is
already wired into the Xcode project, the blocking test plan and CI (E1). Files are split by
entity, with the turn logic in `GameState.swift`, so each story's implementation touches few
files. No app-target changes in this slice: E3 is the first consumer.

## Complexity Tracking

No violations to justify.

## Follow-ups for other slices

- **E3 (#80)**: the game model wraps `GameState` and turns `RuleError` and `StepResult` into
  localized messages; the "capture required" message (FR-MOVE-05) uses `isCaptureRequired` and
  `movablePieces`.
- **E4 (#104)**: searching with full `GameState` copies grows the history on every node; if a
  profile shows it matters, make the position-level step generation public and search on
  `Position` (R2, R9).
- **E5 (#122)**: add `Codable` to `GameState` and its stored types inside the package; the
  history already holds everything undo and repetition need (FR-013).
