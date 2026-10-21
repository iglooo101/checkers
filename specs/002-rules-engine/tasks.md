---

description: "Task list for the rules engine slice (epic E2)"
---

# Tasks: Rules Engine

**Input**: Design documents from `/specs/002-rules-engine/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/engine-api.md, quickstart.md

**Tests**: Tests are MANDATORY (Constitution III). Every user story has acceptance tests in a suite whose type name starts with its story ID (`US1StartAndMoveTests`), and every acceptance test's display name starts with the story ID and lists the FRD IDs it proves, for example `@Test("US3 FR-RULE-07 FR-CHAIN-03: a man crowned mid-chain stops jumping")`. Test tasks come before the implementation tasks they cover and must be observed failing (or failing to compile) before implementation begins. The whole-engine checks are written with the story whose code completes them: the reference counts (SC-002, SC-004) with US3, the random games (SC-003) with US5. All tests use Swift Testing.

**Organization**: Tasks are grouped by user story so each story can be implemented and verified on its own. A test task is complete together with the implementation tasks it covers (red, then green): no commit or push is ever red, so every completed task leaves the package building and all tests passing (Constitution workflow gate 3).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US5)
- Paths are relative to the repository root. Shorthands: `Sources/` is `checkers/CheckersEngine/Sources/CheckersEngine/`; `EngineTests/` is `checkers/CheckersEngine/Tests/CheckersEngineTests/`.

## Conventions used by every task

- Run engine tests with `(cd checkers/CheckersEngine && swift test)`; one story with `swift test --filter US<n>`. `swift test` does not run SwiftLint (*measured* in T001); the Xcode build does, so before pushing a story run `scripts/test.sh`, which builds with SwiftLint and runs the engine tests on the simulator. A story is done when its suite and every earlier suite pass with zero compiler warnings and zero SwiftLint errors.
- The public API is exactly [contracts/engine-api.md](contracts/engine-api.md): names, types, `Sendable` on every public type, typed throws `throws(RuleError)`, step order and rejection order. Anything not listed there is `internal`. Tests use `@testable import CheckersEngine`.
- No force unwraps, `try!` or force casts in `Sources/` (Constitution IV.1); tests may use them (T001). No `print` in `Sources/`; the engine does not log.
- Every source file starts with a `///` doc comment on its main type, as `Side.swift` does, and is formatted with `scripts/format.sh`.
- Test positions are written with the T003 helpers, for example `GameState(["c3": .lightMan, "d4": .darkMan], toMove: .light)`. Every square named in this file is a dark square.
- Commit a story's failing tests together with the implementation that makes them pass (or the tests first, without pushing), so every pushed commit is green. Push after each story; the `CI gate` must pass. Commits are authored by iglooo101 with no AI attribution.
- Before starting a story, move its board tasks to In Progress; when the story is pushed and green, move them to Done and close them (`scripts/project/board_move.py`, then `scripts/project/update_plan.py`). See Board Mapping.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Let engine tests use test-only shortcuts, and record the starting point.

- [X] T001 Create `checkers/CheckersEngine/Tests/.swiftlint.yml` with the same content as `checkers/checkersTests/.swiftlint.yml` (header comment, then `disabled_rules`: `force_unwrapping`, `force_cast`, `force_try`, `implicitly_unwrapped_optional`, `no_print`). Verify with the Xcode build (`xcodebuild build-for-testing` with the `scripts/lib.sh` flags; `swift test` does not run SwiftLint): a temporary `_ = Int("1")!` in `EngineTests/SideTests.swift` gives no lint error, while the same line in `Sources/Side.swift` gives a `force_unwrapping` error, and without the new file the test-file line fails too. Revert all probes.
- [X] T002 [P] Create `specs/002-rules-engine/checklists/validation.md` with one section per quickstart scenario (1–7) and a "Baseline" section; record that `(cd checkers/CheckersEngine && swift test)` passes with only `SideTests`, and its duration.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The value types every story uses: squares and their diagonals, pieces, positions, steps, outcomes and errors (#37; FR-001, FR-002).

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

### Tests (write first) ⚠️

- [X] T003 [P] Create test helpers in `EngineTests/Support/PositionBuilder.swift`: `extension Square { init(_ name: String) }` (force-unwraps `Square(name:)`); `extension Piece { static let lightMan, lightKing, darkMan, darkKing }`; `extension Position { init(_ layout: [String: Piece]) }` using the internal map initializer (T010); and `extension Position: CustomTestStringConvertible` whose `testDescription` is an 8×8 diagram, row 8 on top, `l`/`L` for a Light man/king, `d`/`D` for a Dark man/king, `.` for an empty dark square and a space for a light square. The `GameState` helper is added in T013, when `GameState` exists.
- [X] T004 [P] Write `EngineTests/SquareTests.swift`: `Square(column:row:)` and `Square(name:)` return a square for all 32 dark squares and `nil` "unless both are in range and `column + row` is even (a dark square)": `nil` for `(1, 0)` (b1), `(-1, 0)`, `(0, 8)`, and the names `"b1"`, `"i1"`, `"a9"`, `"a10"`, `"A1"` (names are lowercase), `""`; a1 is dark; `name` round-trips through `Square(name:)` for every square; `Square.all` has 32 squares in index order starting `a1, c1, e1, g1, b2` and ending `h8`. Diagonal tables (internal, T009): the neighbors of d4 in contract order are `c5, e5, c3, e3`; a1 has only the neighbor b2 and the landing square c3; h8 has only the neighbor g7 and the landing square f6; b2's only landing square is d4 (a1, a3 and c1 have no square beyond them). Fails to compile until T008–T009.
- [X] T005 [P] Write `EngineTests/PositionTests.swift`: an empty position has no piece on any square; each of the four pieces placed on each of the 32 squares reads back with `piece(at:)`; removing a piece empties its square; two positions with the same pieces of the same kind on the same squares are equal and hash equally, while differing only in a piece's kind (man vs king) or side makes them unequal; the T003 layout initializer places exactly the named pieces. Fails to compile until T007, T010.
- [X] T006 [P] Write `EngineTests/StepTests.swift`: `Step(from: c3, to: d4)` has `isJump == false` and `captured == nil`; `Step(from: c3, to: e5)` has `isJump == true` and `captured == d4`; `Step(from: e5, to: c3)` captures d4; `Step(from: a1, to: c3)` captures b2; steps that are not one or two diagonal squares long (`c3→c5`, `c3→f6`, `c3→c3`) have `isJump == false` and `captured == nil`. Fails to compile until T012.

### Implementation

- [X] T007 [P] Create `Sources/Piece.swift`: `public enum PieceKind: Sendable, Hashable { case man, king }` and `public struct Piece: Sendable, Hashable` with `side`, `kind` and a public memberwise `init(side:kind:)`.
- [X] T008 [P] Create `Sources/Square.swift`: `public struct Square: Sendable, Hashable` storing an internal index 0–31 (`row * 4 + column / 2`, a1 = 0, h8 = 31); `public init?(column: Int, row: Int)` and `public init?(name: String)` (a lowercase column letter a–h followed by a row 1–8) returning `nil` "unless both are in range and `column + row` is even"; public `column` (0 = a), `row` (0 = row 1) and `name`; `public static let all: [Square]` in index order; an internal `init(index:)` for tables. T004's square tests pass.
- [X] T009 Create `Sources/BoardGeometry.swift` (internal): `enum Direction: CaseIterable` in contract order (toward row 8 lower column, toward row 8 higher column, toward row 1 lower column, toward row 1 higher column) and immutable tables `neighbor(of:_:) -> Square?` and `landing(of:_:) -> Square?` (the square two steps away in that direction), built once from `Square.all` without force unwraps. In `Sources/Side.swift` add internal `forwardDirections` (Light: the two toward row 8; Dark: the two toward row 1) and `farRow` ("row 8 for Light, row 1 for Dark", i.e. `row` 7 or 0). T004 passes.
- [X] T010 Create `Sources/Position.swift`: `public struct Position: Sendable, Hashable` with three internal `UInt32` sets (Light, Dark, kings; bit = square index); `public func piece(at:) -> Piece?`; internal `init()` (empty), `init(_ pieces: [Square: Piece])`, `mutating func place(_:at:)`, `mutating func remove(at:)` and occupancy helpers. Keep the invariants "no square holds both a Light and a Dark piece; every king square is occupied". T005 passes.
- [X] T011 [P] Create `Sources/Outcome.swift` (`WinReason`, `DrawReason`, `Outcome` exactly as in the contract) and `Sources/RuleError.swift` (`public enum RuleError: Error, Sendable, Equatable` with `gameOver`, `notSideToMove`, `captureRequired`, `mustContinueChain`, `illegalStep`, `nothingToUndo`, each documented with its meaning from data-model.md).
- [X] T012 Create `Sources/Step.swift`: `public struct Step: Sendable, Hashable` (`from`, `to`, `init(from:to:)`, computed `isJump` and `captured` as in T006, without force unwraps) and `public struct StepResult: Sendable, Equatable` with `side`, `piece` (before the step), `from`, `to`, `captured`, `crowned`, `turnContinues`, `outcome` and an internal memberwise initializer. T006 passes.

**Checkpoint**: `swift test` passes `SideTests`, `SquareTests`, `PositionTests` and `StepTests`.

---

## Phase 3: User Story 1 - Start a game and make simple moves (Priority: P1) 🎯 MVP

**Goal**: A new game in the standard position, Light to move; men move one square diagonally forward and the turn passes (#38, #40; FR-003, FR-004, FR-008, FR-020, FR-026, FR-027).

**Independent Test**: `swift test --filter US1` (quickstart §2).

### Tests for User Story 1 (MANDATORY - write first) ⚠️

- [X] T013 [US1] Add the `GameState` helper `init(_ layout: [String: Piece], toMove: Side)` (calls the internal `init(position:sideToMove:)`) to `EngineTests/Support/PositionBuilder.swift`, and write `EngineTests/US1StartAndMoveTests.swift` (`struct US1StartAndMoveTests`) with:
  - `US1 FR-RULE-01 FR-SETUP-06`: `GameState()` has a Light man on each dark square of rows 1–3, a Dark man on each dark square of rows 6–8, nothing on rows 4–5, Light to move, `chainSquare == nil`, `outcome == .inProgress` (AS1).
  - `US1 FR-RULE-02`: the opening `legalSteps` are exactly `a3–b4, c3–b4, c3–d4, e3–d4, e3–f4, g3–f4, g3–h4`, in that order (AS2); `movablePieces == [a3, c3, e3, g3]`; `targets(from: c3) == [b4, d4]`; `targets(from: c1) == []`; `isCaptureRequired == false`.
  - `US1 FR-RULE-02`: applying `c3–d4` empties c3, puts a Light man on d4 and makes Dark to move; the result is `side .light, piece .lightMan, from c3, to d4, captured nil, crowned false, turnContinues false, outcome .inProgress` (AS3, FR-027).
  - `US1 FR-RULE-02`: with Light men on d4 and c5 and a Dark man on h8, Light to move, `targets(from: d4) == [e5]`, and `d4–c3` (backward), `d4–f4` (sideways), `d4–f6` (two squares, nothing to jump) and `d4–c5` (occupied) each throw `illegalStep` and leave the state equal to before (AS4); with a Dark man on e5 and a Light man on a1, Dark to move, `targets(from: e5) == [d4, f4]`.
  - `US1`: moving a Dark man on Light's turn throws `notSideToMove`; a step from an empty square throws `illegalStep`; both leave the state unchanged (FR-020).
  - `US1`: a copy of a game is independent: applying `c3–d4` to a copy leaves the original equal to `GameState()`; the same step on two equal states gives equal states and equal results (FR-026).
  Fails to compile until T016.

### Implementation for User Story 1

- [X] T014 [US1] Add `public static let start: Position` to `Sources/Position.swift`: "Light men on the 12 dark squares of rows 1–3, Dark men on those of rows 6–8".
- [X] T015 [US1] Create `Sources/Position+Steps.swift` (internal): `func steps(for side: Side) -> [Step]` returning the simple moves of the side's men along `forwardDirections` onto empty neighbor squares, ordered by from square in `Square.all` order, then by direction.
- [X] T016 [US1] Create `Sources/GameState.swift`: `public struct GameState: Sendable, Equatable` with `public private(set)` `position`, `sideToMove`, `chainSquare` and `outcome`; `public init()` (start position, Light to move, in progress); internal `init(position:sideToMove:)`; public `legalSteps`, `movablePieces` (distinct from squares of `legalSteps`, in order), `targets(from:)`, `isCaptureRequired`; and `apply(_:) throws(RuleError) -> StepResult` (`@discardableResult`) running checks 1, 2, 3 and 6 of the contract's apply table in that order, moving the piece and passing the turn. US1 tests pass.

**Checkpoint**: US1 complete: E3's two-player board could be built on it.

---

## Phase 4: User Story 2 - Capture and play with kings (Priority: P1)

**Goal**: Men capture forward, kings move and capture in all four directions one square at a time, and capturing is mandatory with a free choice of capture (#41, #42, #43; FR-005, FR-006, FR-007, FR-009, FR-020).

**Independent Test**: `swift test --filter US2` (quickstart §2).

### Tests for User Story 2 (MANDATORY - write first) ⚠️

- [X] T017 [US2] Write `EngineTests/US2CaptureAndKingTests.swift` (`struct US2CaptureAndKingTests`) with:
  - `US2 FR-RULE-03 FR-RULE-05`: Light men on c3 and a1 and Dark men on d4 and h8, Light to move: `legalSteps == [c3–e5]`, `movablePieces == [c3]`, `isCaptureRequired == true` (AS1).
  - `US2 FR-RULE-03`: applying `c3–e5` there empties c3 and d4, puts the Light man on e5, makes Dark to move, and the result has `captured == d4` and `turnContinues == false`.
  - `US2 FR-RULE-03`: a Light man on d4 with a Dark man on c3 and b2 empty (plus a Dark man on h8) cannot jump backward: `d4–b2` is not legal and throws `illegalStep` (AS2).
  - `US2 FR-RULE-04`: a lone Light king on d4 (Dark man on h8) has `targets(from: d4) == [c5, e5, c3, e3]`, and `d4–b6`, `d4–f2` throw `illegalStep` (no flying kings; AS3).
  - `US2 FR-RULE-04`: a Light king on e5 with a Dark man on d4 and c3 empty (plus a Dark man on h8) has `legalSteps == [e5–c3]` (backward capture; AS4).
  - `US2 FR-RULE-05`: with a Light man on a3, Dark men on b4 and d6 (a two-jump chain a3–c5–e7), a Light king on h2 and a Dark man on g3 (a one-jump capture h2–f4), and a Dark man on h8, both first jumps are legal: `legalSteps == [h2–f4, a3–c5]` (AS5: not forced to take the longest chain or to capture with a king).
  - `US2 FR-RULE-05`: in the AS1 position, the simple move `a1–b2` throws `captureRequired` and changes nothing (AS6).
  - `US2 FR-RULE-03 FR-RULE-04`: no jump over an own piece (Light men c3, d4), onto an occupied square (Light man c3, Dark men d4, e5), or over two pieces at once (Light king a1, Dark men b2 and c3, and a Light man on g1 so Light still has a move: `a1–c3` and `a1–d4` throw `illegalStep`).
  Fails until T018–T019.

### Implementation for User Story 2

- [X] T018 [US2] Extend `Sources/Position+Steps.swift`: kings' simple moves in all four directions; jumps for men along `forwardDirections` and for kings in all four directions, over an adjacent opposing piece onto an empty landing square (`landing(of:_:)`); `steps(for:)` returns only jumps when any jump exists (FR-007), keeping the contract order.
- [X] T019 [US2] Extend `Sources/GameState.swift`: `isCaptureRequired` is true when the legal steps are jumps; `apply` adds check 5 (`captureRequired`) in contract order; applying a jump removes the piece on `captured` and reports it in the result; the turn still ends after one jump (chains come in US3). US1 and US2 tests pass.

**Checkpoint**: US2 complete: every single step of American checkers is generated and applied.

---

## Phase 5: User Story 3 - Capture chains and crowning (Priority: P1)

**Goal**: Multi-jumps one jump at a time with the chain locked to the jumping piece; crowning on the far row ends the turn, even mid-chain; every step reports what it did; whole turns match the published reference counts (#45, #46; FR-009 to FR-012, FR-020, FR-027; SC-002, SC-004).

**Independent Test**: `swift test --filter US3` and `swift test --filter ReferenceCount` (quickstart §2, §3).

### Tests for User Story 3 (MANDATORY - write first) ⚠️

- [X] T020 [US3] Write `EngineTests/US3ChainAndCrowningTests.swift` (`struct US3ChainAndCrowningTests`) with:
  - `US3 FR-CHAIN-01 FR-CHAIN-02 FR-RULE-06`: Light men on a3 and g1, Dark men on b4, d6 and h8, Light to move; after `a3–c5`, b4 is empty, the man is on c5, Light is still to move, `chainSquare == c5`, `legalSteps == [c5–e7]`, `isCaptureRequired == true`, and the result has `turnContinues == true` (AS1).
  - `US3 FR-CHAIN-02`: in that chain, `g1–h2` (another piece) and `c5–b6` (a simple move) each throw `mustContinueChain` and change nothing (AS2).
  - `US3 FR-CHAIN-03 FR-RULE-06`: then `c5–e7` empties d6, ends the turn (Dark to move, `chainSquare == nil`, `turnContinues == false`; AS3).
  - `US3 FR-RULE-07 FR-CHAIN-03`: a Light man on b6, Dark men on c7 and e7, d8 and f6 empty, Light to move: `b6–d8` crowns (d8 holds a Light king, `crowned == true`), the turn ends although the king could jump e7, and e7 still holds its Dark man (AS4).
  - `US3 FR-RULE-07`: a Dark man on b2 and a Light man on g3, Dark to move: `b2–a1` crowns, the turn passes to Light, and the result has `crowned == true` (AS5).
  - `US3 FR-CHAIN-02`: a branching chain: Light man on c3, Dark men on d4, d6 and f6 (and h8), c7 and g7 empty; after `c3–e5`, `legalSteps == [e5–c7, e5–g7]` and either may be applied.
  - `US3 FR-CHAIN-01`: a king's chain may cross a square again but never jumps a piece twice: a Light king on c1 with Dark men on d2, d4, b4, b2 (and h8) jumps `c1–e3`, `e3–c5`, `c5–a3`, `a3–c1`; after the fourth jump the four Dark men are gone and the turn ends.
  - `US3 FR-027`: for each step applied in the tests above, the result's `side`, `piece` (before the step), `from`, `to`, `captured`, `crowned` and `turnContinues` match the board change: the piece left `from`, stands on `to` (as a king if crowned), and `captured` alone was emptied (AS6).
  Fails until T023–T024.
- [X] T021 [P] [US3] Create `EngineTests/Support/TurnCounter.swift`: `func countTurnSequences(from state: GameState, turns: Int) throws -> Int`, returning 1 when `turns == 0`; otherwise, for each legal step, apply it to a copy and recurse with the same `turns` if the result's `turnContinues`, else with `turns - 1`, summing the counts (a finished game has no legal steps and contributes 0).
- [X] T022 [US3] Write `EngineTests/ReferenceCountTests.swift` (`struct ReferenceCountTests`): a parameterized `@Test("US3 SC-002: complete-turn sequences from the start match the published counts", arguments: [(1, 7), (2, 49), (3, 302), (4, 1_469), (5, 7_361), (6, 36_768), (7, 179_740)])`, with a comment citing OEIS A133046 and Aart Bik's checkers page (research R1); and `@Test("US3 SC-004: the 6-turn count takes under 10 seconds")` timing `countTurnSequences(from: GameState(), turns: 6)` with `ContinuousClock`. Observe depth 7 fail before T023–T024: an engine without chains or crowning counts 180,018 sequences, not 179,740 (*measured* with the research prototype).

### Implementation for User Story 3

- [X] T023 [US3] Add internal `jumps(from:)` (the jumps of one piece) to `Sources/Position+Steps.swift`, and chains to `Sources/GameState.swift`: after a jump that does not crown, if the piece can jump again, set `chainSquare` to its square, keep the side to move and report `turnContinues`; while `chainSquare` is set, `legalSteps` are that piece's jumps only; `apply` adds check 4 (`mustContinueChain`) in contract order (FR-010, FR-011).
- [X] T024 [US3] Add crowning to `apply` in `Sources/GameState.swift`: a man ending any step on its `farRow` becomes a king at once, the result has `crowned == true`, and the turn ends even if the new king could jump (FR-012). US1–US3 tests and `ReferenceCountTests` pass.

**Checkpoint**: US3 complete: whole turns, including chains and crowning, play correctly and match the reference counts (quickstart §3).

---

## Phase 6: User Story 4 - Game endings (Priority: P2)

**Goal**: Loss with no legal moves, resignation, draw by threefold repetition and by 80 turns without progress, with the precedence of FR-019; nothing is accepted after the end (#48, #49, #50, #51, #52; FR-013 to FR-020).

**Independent Test**: `swift test --filter US4` (quickstart §2).

### Tests for User Story 4 (MANDATORY - write first) ⚠️

- [ ] T025 [US4] Write `EngineTests/US4EndingTests.swift` (`struct US4EndingTests`), using the internal `noProgressCount` and `history` where noted, with:
  - `US4 FR-END-01`: a Light man on c3 and a lone Dark man on d4, Light to move: after `c3–e5`, `outcome == .win(winner: .light, reason: .noMovesLeft)`, the result carries the same outcome, and `legalSteps` is empty (AS1).
  - `US4 FR-END-01`: a Light man on b2, a Light king on d2 and a Dark man on a3, Light to move: after `d2–c1`, Dark has a piece but no legal step, and Light wins with reason no moves left (AS2).
  - `US4 FR-END-01`: a game created with the side to move having no pieces (`GameState(["h8": .darkMan], toMove: .light)`) is already over: Dark wins, no moves left.
  - `US4 FR-END-02`: in a new game Dark resigns on Light's turn: `.win(winner: .light, reason: .resignation)`; in the US3 two-jump position after `a3–c5`, Light resigns mid-chain: Dark wins by resignation, the position is unchanged and `chainSquare == nil` (AS3).
  - `US4 FR-END-03`: a Light king on h2 and a Dark king on a7, Light to move, play `h2–g1, a7–b8, g1–h2, b8–a7` twice: after 7 turns the game is in progress; the 8th turn ends it in `.draw(reason: .repetition)`, because the opening position counts as the first occurrence (AS4).
  - `US4 FR-END-03`: only turn starts are recorded: in the US3 two-jump position, both jumps together add exactly one record to `history`, holding the position from before the chain.
  - `US4 FR-END-04`: a Light king on b2 and a Dark king on e7, Light to move; Light's king cycles `c1, d2, e3, d4, c5, b4, c3, b2` and Dark's `f8, g7, h6, g5, f6, e7`, one move each in turn (no position occurs three times and the kings are never adjacent): after 79 turns the game is in progress; the 80th turn ends it in `.draw(reason: .noProgress)` (AS5).
  - `US4 FR-END-04`: the same script with a Light man added on h2, where Light's 79th turn is `h2–g3` instead of a king move: after turn 80 the game is in progress and `noProgressCount == 1`; and a Light man on g7 with a Dark king on a1 and `noProgressCount` set to 79: the crowning move `g7–h8` resets the count to 0 and the game continues (a man's crowning move counts as a man move).
  - `US4 FR-END-01 FR-END-04`: the AS2 position with `noProgressCount` set to 79: `d2–c1` gives the win, not a draw (FR-019).
  - `US4 FR-END-03 FR-END-04`: the AS4 script with `noProgressCount` set to 72, so the 8th turn triggers both draw rules: the outcome is `.draw(reason: .repetition)` (FR-019).
  - `US4 FR-END-05`: there is no draw by agreement: an exhaustive `switch` over `DrawReason` without `default` handles only `.repetition` and `.noProgress`, and `GameState` offers no draw action.
  - `US4 FR-END-01 FR-END-02`: once the game is over (after AS1), any step and `resign(.light)` or `resign(.dark)` throw `gameOver` and leave the state unchanged (AS6).
  Fails until T026–T028.

### Implementation for User Story 4

- [ ] T026 [US4] Add the internal `struct TurnRecord: Sendable, Equatable` (`position`, `sideToMove`, `noProgressCount`) and the internal `history: [TurnRecord]` and `noProgressCount` to `Sources/GameState.swift`. Push a record when the first step of a turn is applied (no chain in progress). When a turn ends, set `noProgressCount` to 0 if the turn captured or the moving piece started the turn as a man, otherwise add 1.
- [ ] T027 [US4] Add end-of-turn evaluation to `Sources/GameState.swift`, in this order (research R6): pass the turn and clear the chain; if the side now to move has no legal step, `.win(winner: <side that moved>, reason: .noMovesLeft)`; else if the current position with that side to move occurs for the third time among the history records plus the current position, `.draw(reason: .repetition)`; else if `noProgressCount` has reached 80, `.draw(reason: .noProgress)`. Add the internal repetition count of the current position. The internal `init(position:sideToMove:)` ends the game at once when the side to move has no legal step. When the game is over, `legalSteps` and `movablePieces` are empty, `targets(from:)` is empty and `isCaptureRequired` is false; `apply` throws `gameOver` (check 1); the result's `outcome` is the outcome after the step.
- [ ] T028 [US4] Add `public mutating func resign(_ side: Side) throws(RuleError)` to `Sources/GameState.swift`: throws `gameOver` if the game is over; otherwise `outcome = .win(winner: side.opponent, reason: .resignation)` and `chainSquare = nil`, with the position and history unchanged (FR-015). US1–US4 tests pass.

**Checkpoint**: US4 complete: every ending and its reason is reported.

---

## Phase 7: User Story 5 - Undo (Priority: P2)

**Goal**: Undo one turn at a time back to the start, mid-chain included, restoring the full state and the repetition record; unavailable at the start and after the end; 1,000 random games stay legal and undo exactly (#54, #55, #56; FR-021 to FR-024; SC-003).

**Independent Test**: `swift test --filter US5` and `swift test --filter RandomGame` (quickstart §2, §4).

### Tests for User Story 5 (MANDATORY - write first) ⚠️

- [ ] T029 [US5] Write `EngineTests/US5UndoTests.swift` (`struct US5UndoTests`) with:
  - `US5 FR-UNDO-02 FR-UNDO-07`: record the state before each turn of the opening `c3–d4, b6–a5, g3–h4, a7–b6` (no captures); one `undo()` makes the state equal (`==`) to the state before the 4th turn, which Dark made: board, side to move, `noProgressCount` and `history` (AS1).
  - `US5 FR-UNDO-01`: three more undos match the states before turns 3, 2 and 1; the last equals `GameState()`, `canUndo` is false, and `undo()` then throws `nothingToUndo` and changes nothing (AS2).
  - `US5 FR-UNDO-05`: in the US3 two-jump position, after `a3–c5`, `canUndo` is true and `undo()` restores the state from before the chain, with Light to move and `chainSquare == nil`; since that was the game's first turn, `canUndo` is then false (AS3).
  - `US5 FR-UNDO-06`: after the US4 AS1 win and after a resignation, `canUndo` is false and `undo()` throws `gameOver` and changes nothing (AS4).
  - `US5 FR-UNDO-07 FR-END-03`: with the US4 AS4 kings, play 7 turns, undo 4, replay the same 4 turns: the game is still in progress (it would be drawn already if the undone occurrences still counted); the 8th turn draws by repetition (AS5).
  - `US5 FR-UNDO-01`: `GameState().canUndo` is false; after `c3–d4` it is true.
  Fails to compile until T032.
- [ ] T030 [P] [US5] Create `EngineTests/Support/SeededGenerator.swift`: `struct SeededGenerator: RandomNumberGenerator` implementing SplitMix64 from a `UInt64` seed.
- [ ] T031 [US5] Write `EngineTests/RandomGameTests.swift` (`struct RandomGameTests`), `@Test("US5 SC-003: 1,000 random games end, stay legal and undo exactly")`: for games 0–999, seed `SeededGenerator` with the game number; record the state at every turn start; apply random legal steps (`legalSteps.randomElement(using:)`) until the outcome is not in progress, failing if a game exceeds 15,360 turns (research R11). After every step, check the data-model invariants: no square holds both sides; every king square is occupied; each side has at most 12 pieces; no Light man on row 8 and no Dark man on row 1; the piece count never grows, is unchanged by a simple move and drops by exactly one on a jump; while in progress, the side to move has a legal step and `noProgressCount` is 0–79; while `chainSquare` is set, it holds a piece of the side to move and `legalSteps` are its jumps. Then, starting from the state recorded at the start of the final turn, undo turn by turn, checking each state equals the recorded one, until it equals `GameState()` and `canUndo` is false. Failure messages name the game number. Fails to compile until T032.

### Implementation for User Story 5

- [ ] T032 [US5] Add `public var canUndo: Bool` (in progress and `history` not empty) and `public mutating func undo() throws(RuleError)` to `Sources/GameState.swift`: throw `gameOver` if the game is over, `nothingToUndo` if `history` is empty; otherwise remove the last record, restore its `position`, `sideToMove` and `noProgressCount`, and set `chainSquare = nil` (contract, undo section). All suites, including `RandomGameTests`, pass.

**Checkpoint**: US5 complete: all five stories and the whole-engine checks pass (quickstart §2–§4).

---

## Phase 8: Polish & Cross-Cutting Concerns

- [ ] T033 Run `scripts/format.sh`, then confirm `scripts/check-format.sh --strict`, `scripts/tests/run.sh` and `(cd checkers/CheckersEngine && swift test)` pass with zero compiler warnings and zero SwiftLint errors.
- [ ] T034 Run every scenario in `specs/002-rules-engine/quickstart.md` (1–7) and record each result in `specs/002-rules-engine/checklists/validation.md`, including the engine suite's duration (target under 60 s), the SC-004 timing, the SC-001 search result (exactly the 21 FRD IDs), and the `xcresulttool` check that `CheckersEngineTests` ran in `scripts/test.sh`.
- [ ] T035 [P] Update `checkers/CLAUDE.md`: the engine's types and `GameState` API (pointing to `specs/002-rules-engine/contracts/engine-api.md`), the test layout and `swift test --filter US<n>`.
- [ ] T036 [P] Update `HANDOFF.md` (current state and lessons learned from the slice) and `EXECUTION_PLAN.md` (close-out checklist).
- [ ] T037 Final verification: push the branch, confirm `CI gate` is green on the last commit, fast-forward `main` (`git push origin <sha>:refs/heads/main`), and confirm SC-005: `grep -rE '^\s*import\s+(SwiftUI|UIKit|WebKit|Combine)' checkers/CheckersEngine/Sources` finds nothing.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: no dependencies.
- **Foundational (Phase 2)**: depends on Setup (T001 for test-only force unwraps); blocks all stories.
- **US1 (Phase 3)**: depends on Phase 2.
- **US2 (Phase 4)**: depends on US1 (`GameState`, simple-move generation).
- **US3 (Phase 5)**: depends on US2 (jumps).
- **US4 (Phase 6)**: depends on US3 (endings are evaluated when a turn ends, including after chains).
- **US5 (Phase 7)**: depends on US4 (`history` and `noProgressCount`; the random games need every ending).
- **Polish (Phase 8)**: depends on all stories.

The stories build one engine, so they run in sequence; each still has its own suite and checkpoint.

### Within Each User Story

- The story's test tasks first; observe them fail (or fail to compile) before implementing.
- Implementation tasks in order (they edit the same files).
- Story complete, with every suite green, before the next one; push and check CI.

### Parallel Opportunities

- T001 and T002.
- T003–T006 (four test files) can be written together.
- T007, T008 and T011 can be written together; T009 and T010 need T008; T012 needs T008 and T011.
- T020 and T021 (US3 tests and the turn counter); T029 and T030 (US5 tests and the seeded generator).
- T035 and T036 can be written together.

## Parallel Example: Phase 2

```bash
Task: "T003 EngineTests/Support/PositionBuilder.swift"
Task: "T004 EngineTests/SquareTests.swift"
Task: "T005 EngineTests/PositionTests.swift"
Task: "T006 EngineTests/StepTests.swift"
```

## Implementation Strategy

### MVP First (User Story 1)

1. Phases 1–2, then US1: a new game and simple moves.
2. **Stop and validate** with `swift test --filter US1`.

### Incremental Delivery

1. US1 → US2 → US3 (all P1: complete move rules, checked against the reference counts) → US4 → US5 (with the random games) → Polish.
2. After each story: all suites green, push the branch, CI green, update the board and `EXECUTION_PLAN.md`.

## Requirement Coverage

FRD requirements in scope (SC-001), by the test tasks that name them:

| FRD IDs | Test tasks |
|---|---|
| FR-RULE-01, FR-RULE-02, FR-SETUP-06 | T013 |
| FR-RULE-03, FR-RULE-04, FR-RULE-05 | T017 |
| FR-RULE-06, FR-RULE-07, FR-CHAIN-01 to FR-CHAIN-03 | T020 |
| FR-END-01 to FR-END-05 | T025 (FR-END-03 also T029) |
| FR-UNDO-01, FR-UNDO-02, FR-UNDO-05, FR-UNDO-06, FR-UNDO-07 | T029 |

Spec requirements and success criteria:

| Spec ID | Tasks |
|---|---|
| FR-001, FR-002 | T004, T005, T007–T010, T013 |
| FR-003, FR-004 | T013–T016 |
| FR-005, FR-006, FR-007 | T017–T019 |
| FR-008 | T013, T016, T017, T019 |
| FR-009 | T006, T012, T017, T019, T020 |
| FR-010, FR-011 | T020, T023 |
| FR-012 | T020, T024 |
| FR-013 | T016, T026, T027 |
| FR-014, FR-019 | T025, T027 |
| FR-015 | T025, T028 |
| FR-016, FR-017 | T025–T027, T029 |
| FR-018 | T025 |
| FR-020 | T013, T016, T017, T019, T020, T023, T025, T027, T029, T032 |
| FR-021 to FR-024 | T029, T032 |
| FR-025 | T001, T037 (and the existing `engine_no_ui_imports` rule) |
| FR-026 | T013, T016 |
| FR-027 | T012, T013, T016, T017, T019, T020, T023, T024, T027 |
| SC-001 | T034 |
| SC-002, SC-004 | T021, T022 |
| SC-003 | T030, T031 |
| SC-005 | T034, T037 |

## Board Mapping

Reconciled with the board in #35 (2026-10-21). Each board task maps to these tasks, and each board issue lists its task IDs:

| Board task | Tasks |
|---|---|
| #37 Board, square and piece types | T003–T012 |
| #38 Starting position | T013 (AS1), T014 |
| #40 Man moves | T013, T015, T016 |
| #41 Man captures | T017 (man captures), T018, T019 |
| #42 King moves and captures | T017 (king), T018 |
| #43 Mandatory capture | T017 (AS1, AS5, AS6), T018, T019 |
| #45 Jump-by-jump chains | T020 (chains, step results), T023 |
| #46 Crowning ends the turn | T020 (AS4, AS5), T024 |
| #48 Game state | T016, T026, T027 |
| #49 No legal moves | T025 (AS1, AS2, precedence), T027 |
| #50 Threefold repetition | T025 (AS4, turn starts, precedence), T027 |
| #51 No progress | T025 (AS5, resets), T026, T027 |
| #52 Resignation | T025 (AS3, AS6, FR-END-05), T028 |
| #54 Turn history | T029 (AS1, AS2, AS5), T032 |
| #55 Undo mid-chain | T029 (AS3), T032 |
| #56 No undo after the end | T029 (AS4), T032 |
| #193 Reference counts and speed (SC-002, SC-004) | T021, T022 |
| #194 Random games (SC-003) | T030, T031 |
| #195 Validate the E2 slice and update docs | T001, T002, T033–T037 |

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Each acceptance test names its story ID (for example `US1`) in its display name or tag
- A test task completes together with the implementation tasks it covers; every commit leaves the app building and all tests passing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
