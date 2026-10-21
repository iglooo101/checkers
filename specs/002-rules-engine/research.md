# Research: Rules Engine

Phase 0 output for `specs/002-rules-engine/plan.md`. Each entry records the decision, why, and
what else was considered. Facts marked *measured* were checked on the development Mac on
2026-10-21.

## Environment facts

| Item | Value |
|---|---|
| Development Mac | Intel Core i9-9980HK (x86_64), macOS 15 (*measured*) |
| Xcode | 26.3, Swift 6.2.4 (*measured*) |
| Engine package | `checkers/CheckersEngine`, swift-tools-version 6.2, iOS 26.2 and macOS 15; contains only `Side` and its test (*measured*) |
| Engine lint | `CheckersEngine/.swiftlint.yml` inherits the app rules; unlike the app's test targets, the engine's test folder has no nested configuration relaxing the force-unwrap family (*measured*) |
| Engine tests in CI | Run inside the blocking `checkers.xctestplan` on the iPhone simulator, Debug build (*measured*) |

## R1. Reference move counts for SC-002

- **Decision**: Check the engine against the published perft counts for American checkers
  (English draughts) from the standard starting position, at depths 1 to 7, in the blocking test
  suite:

  | Turns | Complete-turn sequences |
  |---|---|
  | 1 | 7 |
  | 2 | 49 |
  | 3 | 302 |
  | 4 | 1,469 |
  | 5 | 7,361 |
  | 6 | 36,768 |
  | 7 | 179,740 |

  Deeper values from the same sources, for reference: 8 → 845,931; 9 → 3,963,680;
  10 → 18,391,564.
- **Sources**: OEIS [A133046](https://oeis.org/A133046), "Starting from the standard 12 against
  12 starting position in checkers…", submitted by Jonathan Schaeffer (2007), later terms by Aart
  Bik; and Aart Bik's checkers page ([aartbik.com/strategy.php](https://aartbik.com/strategy.php)),
  which lists the same counts. Both give identical values for every depth used here.
- **Counting convention**: a "move" is a complete turn (a full capture chain is one move), and
  different jump sequences are counted separately, even when they capture the same pieces
  ("duplicate captures are counted separately"; per Bik, such duplicates first occur at depth 12).
  This is exactly what enumerating the engine's steps one jump at a time produces, so the test
  needs no de-duplication.
- **Light moves first**: the sources start with the side traditionally called Black. The starting
  position is symmetric under a 180° rotation of the board, so the counts are the same with Light
  to move (FR-003).
- **Independent check** (*measured*): a throwaway Python counter written from FR-001 to FR-012
  reproduced every value through depth 9 (0.2 s at depth 6, 1.1 s at depth 7, 5.1 s at depth 8,
  23.6 s at depth 9 on the development Mac).
- **What the counts cover** (*measured* with the same counter): captures first occur at turn 3,
  multi-jump chains at turn 6 and crowning at turn 7; no king moves within the first 8 turns. A
  wrong rule that lets a man crowned mid-chain keep jumping changes the count only from depth 9
  (3,963,629 instead of 3,963,680). So the reference counts prove simple moves, mandatory
  capture, chains and crowning by a step, while king movement and the crowning-ends-the-chain
  rule are proven by the US2 and US3 acceptance tests and by the random games of SC-003.
- **Alternatives considered**: depth 6 only, as SC-002's minimum (rejected: it never crowns, and
  depth 7 costs little); depth 8 or 9 (rejected for the blocking suite: 5–24 s even in the
  Python prototype, and the suite runs as a Debug build on CI; the values are recorded above for
  a later release-mode check if E4 needs one).

## R2. Position representation

- **Decision**: `Position` is a fixed-size value holding three 32-bit sets over the 32 dark
  squares: Light pieces, Dark pieces, and kings. Move generation walks squares through
  precomputed neighbor and landing tables (one entry per square and diagonal direction), not
  through bit-shift tricks.
- **Rationale**: A 12-byte value with no heap storage makes copies independent and cheap
  (FR-026, the computer opponent's background search in E4), and makes positions trivially
  `Hashable` and `Equatable` for repetition (FR-016) and for undo checks (SC-003). Walking
  squares through tables keeps the rules readable and testable square by square.
- **Alternatives considered**: an array of 32 optional pieces (rejected: every step copies a
  heap buffer, and the API is no simpler); a dictionary of square to piece (rejected: slower, and
  equality and hashing cost more); a full shift-based bitboard generator (rejected for now:
  faster but harder to read and review; SC-004's budget does not need it, and Constitution VII.4
  requires a profile before such an optimization, which E4 can make if its search needs it).

## R3. Squares and coordinates

- **Decision**: A `Square` is one of the 32 dark squares, stored as an index 0–31
  (`row * 4 + column / 2`, a1 = 0, h8 = 31). It exposes `column` (0–7 for a–h), `row` (0–7 for
  rows 1–8 as seen from Light's side) and `name` ("c3"). It is created from a column and row, or
  from a name, and creation returns `nil` for light squares and out-of-range values. A square is
  dark when `column + row` is even, so a1 is dark (FR-001). `Square.all` lists the 32 squares in
  index order.
- **Rationale**: Matches the FRD's a–h / 1–8 naming (FR-RULE-01, FR-A11Y-01). Failable creation
  means no invalid square exists, without force unwraps (Constitution IV.1). Zero-based
  `column`/`row` map directly onto the board grid in E3.
- **Alternatives considered**: the traditional checkers numbering 1–32 (rejected: the FRD and
  VoiceOver use coordinates); a 64-square board with light squares marked unusable (rejected:
  half the storage is dead and every lookup must check it).

## R4. Steps

- **Decision**: A `Step` is a from square and a to square. A step two diagonal squares long is a
  jump, and its captured square is the square in between (computed, not stored).
- **Rationale**: In American checkers there are no flying kings (FR-006), so from and to
  determine a step completely: a screen can build one from two taps or a drag (FR-MOVE-01,
  FR-MOVE-02), the computer opponent picks one from the legal list, and the engine validates
  either the same way. A stored captured square could disagree with from and to.
- **Alternatives considered**: an enum with simple-move and jump cases (rejected: screens would
  have to know which kind to build before the engine says whether it is legal); a step
  describing a whole multi-jump turn (rejected: FR-009 and FR-CHAIN-01 require one jump at a time).

## R5. Game state, history and undo

- **Decision**: `GameState` is a struct holding the position, side to move, the square of the
  piece in an unfinished chain (if any), the no-progress count, the outcome, and an undo history.
  The history is a list of turn-start records (position, side to move, no-progress count), one
  pushed when the first step of each turn is applied. Undo pops the last record and restores its
  fields, clears the chain and keeps the game in progress. The repetition record is not stored
  separately: the turn starts in the history plus the current position are the record.
- **Rationale**:
  - Undo after a completed turn and undo mid-chain are the same operation, because the record
    for the current turn is pushed at its first jump (FR-021, FR-023).
  - Undoing a turn removes its occurrence from the repetition record by construction (FR-016,
    US5 scenario 5), so the two can never disagree.
  - Restoring copies fields back exactly, so a restored state is equal to the state recorded
    before the turn, which SC-003 checks for every turn of 1,000 games.
  - Everything that affects play is inside one value (FR-013), ready for E5 to save.
- **Alternatives considered**: a separate repetition dictionary of counts (rejected: a second
  structure to keep in step, which undo must decrement); storing whole `GameState` snapshots in
  the history (rejected: nested histories grow quadratically); undoing by reversing steps
  (rejected: un-capturing and un-crowning are easy to get wrong, and draw counters would need
  their own reversal).

## R6. End-of-turn evaluation

- **Decision**: When a turn ends (a simple move, a jump with no further jump, or a crowning),
  the engine:
  1. updates the no-progress count: reset to 0 if the turn captured or the moving piece started
     the turn as a man (this includes the move that crowns it), otherwise add 1;
  2. passes the turn to the other side and clears the chain;
  3. if the side now to move has no legal step (including having no pieces), ends the game: the
     side that moved wins, reason "no moves left" (FR-014);
  4. otherwise, if the current position with the side to move now occurs for the third time
     among the turn starts (the history plus the current position), ends the game in a draw by
     repetition (FR-016);
  5. otherwise, if the no-progress count has reached 80, ends the game in a draw by no progress
     (FR-017).
- **Rationale**: The order is the precedence in FR-019: a win beats a draw, and repetition beats
  no progress. Counting only turn starts means positions in the middle of a chain are never
  counted (FR-016). A capture or a man move cannot be reversed, so a repeated position can only
  lie within the last no-progress run; the scan may stop there, but a plain scan is fast enough
  for game-length histories and is used unless measurement says otherwise.
- **Alternatives considered**: checking the draw rules before the no-moves rule (rejected:
  contradicts FR-019); counting positions after every step (rejected: FR-016 excludes positions
  mid-chain).

## R7. Rejections and their order

- **Decision**: `apply`, `resign` and `undo` use typed throws with one error enum, `RuleError`
  (Constitution IV.2). A rejected call changes nothing. `apply` checks, in this order: game over;
  no piece on the from square (not a legal move); the piece belongs to the side not to move (not
  that side's turn); a chain is in progress and the step is not a jump by the chain's piece
  (chain must continue with the same piece); a capture is required and the step is not a jump
  (capture required); the step is not among the legal steps (not a legal move). `undo` throws
  game over, or nothing to undo at the start. `resign` throws only game over.
- **Rationale**: FR-020 lists these reasons. The order reports the most useful reason first,
  so a screen can tell the player "capture required" (FR-MOVE-05) rather than "not a legal
  move". The full table is in `contracts/engine-api.md`.
- **Alternatives considered**: returning `Bool` or an optional (rejected: loses the reason);
  separate error types per operation (rejected: the screens handle them the same way).

## R8. Concurrency and isolation

- **Decision**: Every public engine type is a struct or enum, declares `Sendable` explicitly
  and is not isolated to any actor. The engine is synchronous; it has no `async` API, actors or
  tasks. Lookup tables are immutable `static let` constants.
- **Rationale**: The package has no default actor isolation (unlike the app target), so its code
  is nonisolated. Value types that are `Sendable` can be copied into a background task for the
  computer opponent's search (E4, Constitution VII.3) without data races. Public types must
  declare `Sendable` themselves, because the compiler does not infer it across modules. Immutable
  tables are constants, not stateful singletons (Constitution II.3).
- **Alternatives considered**: an actor owning the game (rejected: the game state is a value
  that screens and the search copy; an actor adds `await` without protecting anything);
  `@MainActor` types (rejected: would block background search).

## R9. Public API and scope

- **Decision**: Public: `Side` (existing), `PieceKind`, `Piece`, `Square`, `Position` (read
  only, plus the starting position), `Step`, `StepResult`, `Outcome` with its reasons,
  `RuleError` and `GameState` (new game, queries, apply, resign, undo). Internal, used by tests
  through `@testable import`: creating a game from any position and side to move, editing
  positions, move generation on a bare position, the no-progress count and the repetition
  count.
- **Rationale**: The screens (E3), the computer opponent (E4) and saving (E5) need the public
  part; constructed positions are only needed by tests in this slice (Constitution VIII.3).
  Making an internal declaration public later is a one-word change.
- **Not added**: saving formats (`Codable`, E5 #122); search helpers (E4); rule variants;
  user-facing text. The engine returns structured values and screens build localized text from
  them (Constitution V.4).

## R10. Test approach

- **Decision**:
  - Swift Testing only. Acceptance tests are grouped by story in suites whose type names start
    with the story ID (`US3ChainAndCrowningTests`), so `swift test --filter US3` runs one story.
    Every acceptance test's display name starts with its story ID and lists the FRD IDs it
    proves ("US3 FR-RULE-07 FR-CHAIN-03: crowning mid-chain ends the turn"), so SC-001's
    coverage can be checked with a search of the test sources (Constitution III.3).
  - Tests build positions from a short map of square names to pieces through a test-target
    helper, and a `CustomTestStringConvertible` conformance in the test target prints positions
    as an 8×8 diagram in failure messages.
  - SC-002: a counter in the test target walks complete turns through the public API (expanding
    chains step by step) and compares depths 1–7 with R1.
  - SC-003: 1,000 games of random legal steps from a seeded generator (a small SplitMix64
    `RandomNumberGenerator` in the test target), so failures reproduce. After every step it checks
    the invariants in `data-model.md`; each game must end within the turn bound derived from the
    rules (see R11); then it undoes turns as described in R11.
  - SC-004: a test times the depth-6 count with `ContinuousClock` and requires under 10 s.
  - SC-005: the tests run with `swift test` in the package, and the existing
    `engine_no_ui_imports` lint rule keeps UI frameworks out.
  - The engine's test folder gets the same nested lint configuration as the app's test targets
    (relaxing the force-unwrap family and `no_print`), as the E1 lint contract states for every
    test target.
- **Rationale**: Seeded randomness makes SC-003 deterministic; story-named suites give the
  story-to-test mapping Constitution III asks for.
- **Alternatives considered**: `SystemRandomNumberGenerator` (rejected: failures would not
  reproduce); XCTest (rejected: Constitution III.2).

## R11. SC-003 and undo after the game ends

- **Decision**: In the random-game test, undo starts from the state at the start of each game's
  final turn (the last state still in progress), and undoing every earlier turn one by one must
  match the state recorded before each turn, back to the starting state. The spec's SC-003 is
  worded accordingly.
- **Rationale**: FR-024 makes undo unavailable once the game has ended, so the final turn cannot
  be undone after it ends. The game must still terminate: men only move forward and captures
  remove pieces, so a game has at most 24 × 7 = 168 man moves and 23 captures, with at most 79
  other turns before each of them and after the last (FR-017). That bounds a game at
  (168 + 23 + 1) × 80 = 15,360 turns; the test fails at that bound instead of hanging.
- **Alternatives considered**: letting undo work after the end in tests only (rejected: tests
  would not test the shipped rules).

## R12. Performance budget

- **Decision**: SC-004 is checked by the test in R10 (depth 6 under 10 s). The whole engine
  suite should run in under 60 s with `swift test` on the development Mac; implementation
  records the measured time in `checklists/validation.md`.
- **Rationale**: Constitution VII.4 requires measurements, not estimates. The Python prototype
  (R1) needed 0.2 s for depth 6, so the budget leaves a wide margin even for a Debug build, and
  the SC-004 test turns the claim into a measurement on every run.
- **Alternatives considered**: a performance-tuned generator now (rejected: see R2).
