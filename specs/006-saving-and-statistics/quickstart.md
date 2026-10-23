# Quickstart: validating saving and statistics

Run these scenarios to prove the slice works. Each names the user story or success criterion it
validates. Commands run from the repository root. Behavior is in
[contracts/saved-game.md](contracts/saved-game.md) and [contracts/screens.md](contracts/screens.md).

## Prerequisites

- As for E3 to E4: Xcode 26.3 and the iPhone 17 simulator on iOS 26.2
  (`specs/003-game-experience/quickstart.md`).

## 1. All blocking tests (SC-001, SC-003 to SC-005, SC-007, SC-008)

```sh
scripts/test.sh
```

Expected: the blocking test plan passes, including the engine's coding tests, the saving,
Continue, abandon, unreadable-save and record tests, the UI tests and the audit. Every FRD ID of
the slice is named by a test:

```sh
grep -rhoE 'FR-(SAVE-0[1-5]|STAT-0[1-6]|END-08|NAV-0[23]|SETUP-0[45]|UNDO-08|PRIV-01)' checkers/checkersTests checkers/checkersUITests checkers/CheckersEngine/Tests | sort -u
```

## 2. Continue after closing the app (US1, SC-001, SC-002)

On the iPhone 17 simulator:

- New game → Computer, Easy, Light → Start. Play three moves.
- Close the app from the app switcher, open it: Home shows Continue first.
- Continue: the same position, Light to move, the player's pieces at the bottom; Undo takes back the
  last pair of moves.
- Play a move and, while the computer thinks, press Home on the simulator; close the app from the
  app switcher; open it and Continue: the computer moves (perhaps differently), then it is your
  turn.
- Start a capture chain with a two-player game, press Home on the simulator mid-chain, close and
  reopen the app, Continue: the same piece must keep jumping.

## 3. New game with a saved game (US2)

- With a saved game, New game → Start: "Abandon current game?". Cancel: setup stays; back to Home,
  Continue is still there.
- Start again → Abandon: the new game starts; back to Home, Continue now leads to the new game.
- Resign the game: the result panel; Home shows no Continue; Play again starts at once.

## 4. Record (US3, SC-004)

- Open Statistics with no finished game against the computer: "No games yet." and the sentence
  about finishing a game.
- Finish games against the computer at Easy and Medium (resign one, win or lose another), and a
  two-player game: Statistics counts only the computer games, at their levels, each once.

## 5. A damaged saved game or record (US4, SC-005)

Covered by the UI tests that launch the app with damaged data:

- `-savedGame <hex>`: Home shows "Your previous game couldn't be restored." once, then no
  Continue; a new game starts without the abandon question.
- `-record <hex>`: Home shows "Your record couldn't be restored and starts again from zero." once;
  Statistics shows the empty state.

## 6. Accessibility (SC-007)

With the audit tests and by hand: Home with Continue, Statistics empty and with a record, at the
largest accessibility text size and in Dark Mode on the iPhone SE (3rd generation); VoiceOver reads
each Statistics block as one sentence.

## 7. CI

Push the branch: `build-and-test` and `engine-strength` pass and `CI gate` is green.
