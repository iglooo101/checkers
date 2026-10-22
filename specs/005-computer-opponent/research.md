# Research: Computer Opponent

Phase 0 output for `specs/005-computer-opponent/plan.md`. Each entry records the decision, why, and
what else was considered. Facts marked *measured* were checked on the development Mac (Intel Core
i9-9980HK, 2.4 GHz, Swift 6.2.4) on 2026-10-22; the benchmark and prototype were throwaway
programs outside the repository.

## Environment facts

| Item | Value |
|---|---|
| Engine API | `GameState` with `legalSteps`, `apply(_:)` returning a `StepResult`, `undo()`, `resign(_:)`; values, `Sendable`, synchronous and pure (`specs/002-rules-engine/contracts/engine-api.md`) |
| Engine speed through the public API | Turn-sequence counts from the start: Release 175,000–182,000 steps applied per second (6 turns 0.26 s, 7 turns 1.28 s, 9 turns 30.9 s); Debug 10,600–11,000 per second (6 turns 4.4 s, 7 turns 20.7 s) (*measured*) |
| Where the time goes | Time Profiler, Release, 8-turn count, 6,148 samples: 55% inside array growth, 33% of self time in `malloc`, `free` and object allocation; `GameState.legalSteps` 48% and `endTurn` 39% inclusive, because ending a turn generates every step of the next side only to see whether one exists (*measured*) |
| Allocation-free prototype | Turn generation on three 32-bit sets with per-square neighbor tables: reproduces the published counts for 1–10 turns (10 turns: 18,391,564); Release about 25 million turns per second (9 turns 0.20 s, 10 turns 0.93 s), unoptimized about 400,000 per second (8 turns 2.7 s) (*measured*) |
| Square bits | `Position` keeps Light, Dark and kings as 32-bit sets indexed `row * 4 + column / 2`, the prototype's layout, so converting inside the package costs nothing |
| App concurrency | App target: default isolation `MainActor`, approachable concurrency on, so a plain `nonisolated async` function runs on its caller's actor; heavy work needs `@concurrent` (Constitution VII.3) |
| Game screen | `GameSession` (taps, drags, undo, resign, square states, announcer, `focusSquare`), `AppRouter` (path, session, setup saved on every change, leave confirmation), `GameSetup.defaults` Two players, `canStart` false for Computer, setup note `setup.computerNote` (E3, E7) |
| CI | `build-and-test` (Debug, iPhone 17 simulator) takes 15–25 minutes of its 30-minute limit and runs the engine tests in Debug; `CI gate` decides from it (`scripts/ci/gate.sh`) |

## R1. A fast turn generator for the search

- **Decision**: The search gets its own allocation-free turn generator inside `CheckersEngine`
  (`TurnGenerator`, internal): Light, Dark and kings as 32-bit sets, neighbor and landing tables
  per square and direction, complete turns (every jump of a chain, chains that end on crowning)
  written into reusable per-ply buffers, no arrays created per node. `GameState` stays the
  referee: the root turns come from `GameState` (`legalSteps` and `apply`, recursively through
  chains), and every step the computer plays is applied with `GameState.apply`, so an illegal step
  could never reach the board (FR-004). The generator is checked against `GameState` in three
  ways: the published turn counts for 1–7 turns (Debug, blocking) and 1–9 (Release, strength
  job); for 1,000 seeded random positions, the set of positions after each complete turn equals
  the set reached through `GameState`; and the strength matches play every turn through
  `GameState`.
- **Rationale**: The profile shows allocation, not the rules, is the cost. The prototype is about
  140 times faster in Release and about 37 times in Debug, which turns Hard from a 6-turn search
  into a 10-turn or deeper one inside the same time (R4). Keeping `GameState` as the only way
  steps reach the board means the second generator can make the computer weaker if it were wrong,
  never illegal.
- **Alternatives considered**: searching with `GameState.apply` (rejected: 175,000 steps per
  second in Release caps Hard at about 6 turns in half a second, and Debug at 11,000 per second
  makes the app and tests unusable at Hard); rewriting `Position.steps` without arrays (rejected:
  the public API returns arrays of single steps for the screen, E2's verified engine would change
  for no user-visible gain, and per-call results would still allocate); a transposition table or
  an opening book first (rejected: not needed for the strength targets until measured, Principle
  VIII.3).

## R2. Search

- **Decision**: Negamax alpha-beta over complete turns with iterative deepening (depth 1, 2, … up
  to the level's maximum).
  - **Move order**: the previous iteration's best turn first, then turns that capture more
    pieces.
  - **Captures at the horizon**: at depth 0, if the side to move must capture, the search
    continues with captures until the position is quiet, so it never stops in the middle of an
    exchange.
  - **Endings**: a side with no turn loses (score −10,000 plus the distance in turns, so faster
    wins and slower losses are preferred); a position that already occurred in the game (from the
    engine's turn records) or on the search path with the same side to move scores 0; a turn that
    brings the no-progress count to 80 scores 0 (FR-END-03, FR-END-04).
  - **Stopping**: the search counts nodes and checks a `shouldStop` closure every 1,024 nodes. An
    iteration that is stopped or that exceeds the level's node limit is discarded, and the best
    turn of the last completed iteration is played. Depth 1 always completes.
  - **Choosing among good turns**: root turns are searched with a window wide enough to score
    every turn within the level's margin of the best exactly; the turn is drawn at random from
    those (R5).
- **Rationale**: Standard, well-understood checkers search; depth- and node-limited iterations
  make a level's play depend only on the position and the seed, which the strength tests need
  (R6), while the closure lets the app add a time limit (R7).
- **Alternatives considered**: Monte Carlo tree search (rejected: weaker per node in a tactical
  game with forced captures, and harder to make repeatable); a fixed depth without iterative
  deepening (rejected: no fallback when time runs out); principal-variation search and killer
  moves (deferred: add only if the matches or timing show a need).

## R3. Evaluation

- **Decision**: A score from the side to move's view, in points where a man is 100. Starting
  weights, tuned during implementation by the matches (R6) and recorded here when final:
  - man 100, king 130;
  - each man 2 points per row advanced from its own back row;
  - 8 points for each man still on its own back row while the opponent has men (guards against
    crowning);
  - 5 points for each piece on the center squares c5, e5, d4, f4;
  - when ahead in material, a bonus for trading down: the lead times (24 − pieces on board) / 8,
    so a side ahead prefers simpler positions and avoids no-progress draws.
- **Rationale**: Material dominates checkers; advancement, back-row and center terms are the
  classic cheap positional terms; the trade-down term converts winning endgames. Every term is a
  population count on the three sets, so evaluation stays fast.
- **Alternatives considered**: a trained or table-driven evaluation (rejected: far beyond what
  "a challenge for an experienced casual player" needs); material only (rejected: aimless play
  in quiet positions and drawn won endgames).

## R4. Difficulty levels

- **Decision**: A public `ComputerLevel` (easy, medium, hard) in the engine, each with a maximum
  depth, a node limit and a random margin. Starting values, tuned until SC-003 and SC-004 hold
  and then recorded here:

  | Level | Maximum depth (turns) | Node limit | Random margin |
  |---|---|---|---|
  | Easy | 2 | none | 40 points |
  | Medium | 4 | none | 8 points |
  | Hard | 16 | set by measurement: Hard's slowest turn in the match games at most 0.5 s on the development Mac in Release | 0 (only exact ties) |

  The app maps its `Difficulty` to `ComputerLevel` in one place.
- **Rationale**: Depth sets strength; the margin makes Easy miss the best move often (a beginner
  can win, FR-012) and gives Medium and Hard variety (FR-013). Measured on this Mac, a full
  10-turn generation takes 0.93 s, so an alpha-beta search to 10 turns or more fits well inside
  0.5 s; the node limit keeps Hard's worst positions in budget on every device, and phones from
  the last two generations are faster per core than this Mac.
- **Alternatives considered**: levels defined by thinking time (rejected: strength would depend on
  the device and the build, and matches would not repeat); random blunders at Easy (rejected as
  the first approach: a margin is simpler and tunable; revisit if the playtest finds Easy too
  strong).

## R5. Randomness that repeats in tests

- **Decision**: `chooseTurn` takes a `seed: UInt64` and draws with a small seeded generator
  (SplitMix64) inside the engine. The app draws a new seed for every computer turn with the
  system generator; tests and matches pass fixed seeds.
- **Rationale**: The engine stays pure (same inputs, same turn), matches and acceptance tests
  repeat exactly, and games in the app still vary (FR-013).
- **Alternatives considered**: an `inout RandomNumberGenerator` parameter (rejected: awkward to
  pass into a `@concurrent` task and not `Sendable`); no randomness at Hard (rejected: games
  would repeat move for move).

## R6. Strength matches (SC-002, SC-003)

- **Decision**: A separate engine test target, `CheckersEngineStrengthTests`, plays two matches:
  Medium against Easy and Hard against Medium. Each has 50 openings, each opening being two turns
  drawn at random from a fixed seed, and plays every opening twice with the sides swapped: 100
  games per pairing. Every step goes through `GameState.apply` (SC-002: all legal, every game
  ends by the rules). A win counts 1 and a draw 0.5; the stronger level must score at least 70%.
  The target is not in the Xcode test plan; it runs with `swift test -c release` in a new CI job,
  `engine-strength`, in parallel with `build-and-test`, and `CI gate` requires both. The job also
  runs the turn generator's 1–9-turn counts. Target: under 15 minutes on the CI runner.
- **Rationale**: 200 games at Hard and Medium take minutes in Release but hours in Debug, and the
  build-and-test job has no room left; a parallel job keeps the check blocking (Constitution
  III.5) without slowing the main job. Swapped sides and random openings stop one level winning
  by always having the first move or always reaching the same game.
- **Alternatives considered**: matches in the Debug test plan with fewer games (rejected: below
  the 100 games the clarification set, and still slow); a non-blocking local-only run like the
  launch timing (rejected: a level could silently weaken, Constitution III.5); fixed published
  openings (rejected: random two-turn openings from a seed are enough for variety and need no
  data file).

## R7. Running the search off the main actor

- **Decision**: The live opponent (`EngineComputerOpponent`, app) runs `ComputerPlayer.chooseTurn`
  inside a `@concurrent` function, so it runs on the cooperative pool, never on the main actor.
  Its `shouldStop` closure returns true when the task is cancelled or 0.8 s have passed since
  thinking began (measured with `ContinuousClock`). A cancelled task's result is discarded.
- **Rationale**: Constitution VII.3 and FR-014 (the main actor stays free); with approachable
  concurrency a `nonisolated async` function would inherit the main actor, so `@concurrent` is
  required. The 0.8 s limit is a safety net that bounds the first step at about 0.85 s in every
  build (FR-008), while in Release the node limit normally ends Hard's search earlier.
- **Alternatives considered**: an actor for the search (rejected: no shared state to protect; a
  function is simpler); `Task.detached` (rejected: loses structured cancellation); a time limit
  inside the engine (rejected: the engine has no clocks, and matches must repeat).

## R8. The computer's turn on the game screen

- **Decision**: `GameSession` drives the computer's turn as a `Task` it owns, through two injected
  services: `ComputerOpponent` (chooses a turn: live engine search, or scripted turns in tests and
  previews) and `TurnPacer` (pauses: live `Task.sleep`, or a manual pacer in tests). The timeline
  is in [contracts/computer-turn.md](contracts/computer-turn.md):
  1. The turn starts when a player's turn ends with the game in progress, or when a game starts
     with the computer to move (FR-005). The router starts it after creating a session.
  2. Thinking and the 0.5 s minimum pause run together, so the first step appears after whichever
     is longer (FR-008).
  3. The first step is applied; before each further jump the pacer pauses 0.5 s (FR-009,
     Clarifications).
  4. While the game screen is covered by Rules or Settings, the next step waits; on return it
     appears after a fresh 0.5 s pause (FR-017). The router tells the session when the game
     screen is covered.
  5. Undo, resign, leaving or a new session cancels the task; after every pause the task checks
     for cancellation before touching the board, so a cancelled turn never changes it (FR-015,
     FR-016, FR-020).
- **Rationale**: Keeps every rule testable without UI (Constitution II.2) and the timing testable
  without waiting (II.3). Running thinking and the pause together meets "even if it chose sooner"
  without measuring elapsed time.
- **Alternatives considered**: driving the turn from the view (`.task`) (rejected: logic in a view
  and untestable); an injected `Clock` (rejected: a test clock is more code than a two-method
  pacer, and the pacer records exactly which pauses were asked for).

## R9. Undo against the computer

- **Decision**: In a computer game, Undo cancels the computer's turn, then undoes at least once and
  until it is the player's turn. This covers every case with one rule: between turns it removes
  the computer's reply and the player's turn (FR-018); while the computer thinks it removes the
  player's turn; during the computer's chain it removes the partial chain and the player's turn
  (FR-020); during the player's own chain it removes the partial chain (FR-021). `canUndo` runs
  the same rule on a copy of the state: available only if it reaches a turn of the player, so it
  is unavailable before the player's first move, also when the computer opened as Light
  (FR-019). Two-player undo is unchanged.
- **Rationale**: Uses only `GameState.undo()` (the engine contract foresaw "E4 composes two calls
  for undo against the computer"); a copy costs a few hundred bytes at most and is computed on
  demand.
- **Alternatives considered**: a new engine query for the number of turns played (rejected: the
  copy-based rule needs no API change and also holds for games that start from any position).

## R10. VoiceOver for the computer's moves

- **Decision**: Each computer step is announced through the existing `Announcer` with the step
  sentences of E7. A step that continues the chain has no follow-up (no "Jump again."); the last
  step is followed by the result or the player's turn ("Light to move."). `focusSquare` is not
  changed by computer steps (FR-025). During the computer's turn square states are "none" and the
  turn indicator reads "Dark is thinking…" or "Light is thinking…" (FR-007, FR-026). An undo
  during the computer's turn announces "Move undone. Light to move." as any undo.
- **Rationale**: Same sentences as the player's moves (FR-023); "Jump again." is an instruction
  to the player; keeping focus lets the VoiceOver player return to the board where they were.
- **Alternatives considered**: announcing "Dark is thinking" when the turn starts (rejected: the
  player's step announcement already ends with "Dark to move.", and a second announcement would
  cut it off).

## R11. Game setup

- **Decision**: `GameSetup.defaults` becomes Computer, Easy, Light (FR-002); `canStart` and the
  setup note go (FR-001); `AppRouter` saves the setup when a game starts instead of on every
  change (FR-003). Stored choices from E3 load as before.
- **Rationale**: The FRD's defaults and wording ("used in the previous game"); E3's choices were
  interim (E3 spec, Clarifications).
- **Alternatives considered**: keeping save-on-change (rejected: a choice abandoned in setup
  would become the next default, against FR-SETUP-03's wording).

## R12. Accessibility of the new states

- **Decision**: The thinking indicator is the turn indicator's header text ("Dark is thinking…")
  with a system `ProgressView` beside it, hidden from VoiceOver so the header is read once. The
  audit test drops the allow-list entry for the disabled Start and audits Game setup with
  Computer chosen and Start available, and a computer game's screen on the player's turn and with
  the result panel. The thinking state lasts about 0.5–0.85 s, shorter than an audit run, so it
  is checked by a UI test that reads the header while the computer thinks, and by previews at the
  largest text size and in Dark Mode; FR-027 is aligned with this (spec alignment in the plan).
- **Rationale**: An audit of a state that changes mid-run would be flaky; the indicator uses only
  primary text and a system control, which the audit already accepts on other screens.
- **Alternatives considered**: a launch argument that slows the computer for the audit (rejected:
  test-only behavior in the shipped app).

## R13. Tests

- **Decision**: Engine (`CheckersEngineTests`, Debug, blocking): turn-generator counts 1–7 and the
  random-position cross-check; search tests on small positions (takes a free piece, takes the
  winning shot, avoids losing a piece at depth 2, prefers the faster win, scores repetition and
  no progress as draws); determinism by seed; node limit and stop closure respected; at every
  level, 20 seeded self-play games stay legal. Strength (`CheckersEngineStrengthTests`, Release,
  CI job): the matches and counts of R6. App (`checkersTests`): the computer turn with a scripted
  opponent and a manual pacer: timeline, input lock, chains, first move as Light, Play again,
  cancel by undo, resign and leaving, holding while covered, announcements, focus, undo rules,
  setup; a live-opponent test checks that a main-actor task completes while a Hard search runs.
  UI (`checkersUITests`): a computer game with Easy (start, the thinking header, the reply, undo),
  and the audit. Acceptance tests name US1–US5.
- **Rationale**: Every rule is tested without waiting or UI; only the matches need Release.
- **Alternatives considered**: UI tests that play whole games against the computer (rejected:
  slow and nondeterministic, since the app seeds each turn at random).

## R14. Logging

- **Decision**: A new `Log.computer` category: one debug-level line per computer turn with the
  level, the depth reached, the nodes searched and the thinking time; an error if the opponent
  returns no turn while the game is in progress (it then plays the first legal turn).
- **Rationale**: Principle IX; makes Hard's timing on a real phone visible in Console without
  personal data.
- **Alternatives considered**: signposts (deferred to E8's hitch check, #182).
