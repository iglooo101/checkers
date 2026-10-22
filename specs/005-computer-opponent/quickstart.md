# Quickstart: validating the computer opponent

Run these scenarios to prove the slice works. Each names the user story or success criterion it
validates. Commands run from the repository root. Behavior is in
[contracts/computer-player.md](contracts/computer-player.md) and
[contracts/computer-turn.md](contracts/computer-turn.md).

## Prerequisites

- As for E3 and E7: Xcode 26.3 and the iPhone 17 simulator on iOS 26.3
  (`specs/003-game-experience/quickstart.md`).
- For SC-005: a recent iPhone with a Release build installed from Xcode (or the closest
  available measurement, recorded as such).

## 1. All blocking tests (SC-001, SC-006 to SC-010)

```sh
scripts/test.sh
```

Expected: the blocking test plan passes, including the engine's turn-generator and search tests,
the computer-turn, undo and announcement tests, the setup tests, the computer-game UI test and the
accessibility audit. Every FRD ID of the slice is named by a test:

```sh
grep -rhoE 'FR-(AI-0[1-6]|MOVE-04|UNDO-0[34]|A11Y-03)' checkers/checkersTests checkers/checkersUITests checkers/CheckersEngine/Tests | sort -u
```

## 2. Strength matches and counts (SC-002, SC-003)

```sh
(cd checkers/CheckersEngine && swift test -c release --filter CheckersEngineStrengthTests)
```

Expected: Medium scores at least 70 of 100 against Easy and Hard at least 70 of 100 against
Medium; every game ends and every step is legal; the turn generator matches the published counts
for 1–9 turns. The test output prints both scores and Hard's slowest turn; record them in
`checklists/validation.md`. CI runs the same command in the `engine-strength` job.

## 3. Play the computer (SC-001, US1, US3, US4)

On the iPhone 17 simulator:

- New game → Computer, Easy, Light → Start. Move; the turn indicator reads "Dark is thinking…",
  the board ignores taps, and the reply appears after about half a second.
- Play until the computer makes a double jump: each jump appears about half a second apart.
- Undo: your move and the computer's reply are taken back. Move again, and choose Undo while it
  thinks: your move is taken back and the computer does not move.
- While it thinks, open Rules, wait two seconds and come back: the board is as you left it, then
  the reply appears.
- New game as Dark: the computer opens as Light; Undo is unavailable until you have moved.
- Resign while it thinks: the result panel shows your resignation and no further move.

## 4. Playtest (SC-004, US2)

Play three games against Easy as a beginner would (no lookahead), and three against Hard trying
your best. Record the results in `checklists/validation.md`. Expected: at least one win against
Easy; Hard wins or draws at least one game.

## 5. Timing on an iPhone (SC-005)

With a Release build on the iPhone, play a game at Hard and watch Console for the `computer`
category: each turn logs its thinking time. Expected: the first step of every computer turn
appears 0.5–1 s after it starts (at least 95% of turns), never later than 1.5 s. Record the
slowest turn.

## 6. VoiceOver (US5)

With VoiceOver on, play a few moves against the computer: each of its moves is announced once
("Dark c5 to d4. Light to move."), each jump of its chain separately, and focus stays where you
left it.

## 7. CI

Push the branch: `build-and-test` and `engine-strength` pass and `CI gate` is green.
