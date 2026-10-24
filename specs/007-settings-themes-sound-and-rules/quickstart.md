# Quickstart: validating settings, themes, sound and rules

Run these scenarios to prove the slice works. Each names the user story or success criterion it
validates. Commands run from the repository root. Behavior is in
[contracts/settings-and-sound.md](contracts/settings-and-sound.md),
[contracts/screens.md](contracts/screens.md) and [contracts/rules-content.md](contracts/rules-content.md).

## Prerequisites

- As for E3 to E5: Xcode 26.3 and the iPhone 17 simulator on iOS 26.2
  (`specs/003-game-experience/quickstart.md`).
- For §5: an iPhone with the app installed from Xcode, and a music app.

## 1. All blocking tests (SC-001 to SC-003, SC-006, SC-007, SC-009)

```sh
scripts/tests/run.sh   # includes scripts/make-sounds.py --check
scripts/test.sh
```

Expected: the script tests pass, including the sound recipe check; the blocking test plan passes,
including the settings store and hints tests, the contrast tests for all three themes in both
appearances, the sound choice tests, the Rules picture and word-count tests, the UI tests and the
audit. Every FRD ID of the slice is named by a test or a manual check below:

```sh
grep -rhoE 'FR-(SET-0[1-4]|SND-0[1-5]|HELP-0[12]|GAME-07|AID-0[1-4]|NAV-04|A11Y-0[45]|PRIV-0[12]|PLAT-03)' checkers/checkersTests checkers/checkersUITests | sort -u
```

## 2. Move hints (US1, SC-001)

On the iPhone 17 simulator:

- Home → Settings: Classic is chosen, Sound effects and Move hints are on.
- Turn Move hints off, go back, New game → Two players → Start: no rings, no dots; tap c3: it is
  marked, and tapping d4 moves it.
- Game menu → Settings → Move hints on → back: the movable pieces have rings again, in the same
  position.
- With hints off, set up a capture (c3–d4, f6–e5): tapping g3 still says a capture is required.
- Close the app from the app switcher, reopen: Settings shows hints as you left them. Put them back
  on.

## 3. Rules (US2, SC-006)

- Home → Rules: seven sections from "The board" to "Undo and resign", each with its picture; the
  chain section has two. The text reads in a minute or two.
- In a game against the computer, play a move and open Rules from the game menu while it thinks;
  go back: the computer's move comes after the usual pause, in the same position.
- VoiceOver on: swipe through Rules; each heading is read as a heading, each picture as its
  description; the rotor's Headings moves between sections (FR-025's header trait; XCUITest
  cannot read traits, so this is checked by hand).

## 4. Themes, visual review (US3, FR-012, SC-002)

- Settings: the three theme rows show their small boards. Choose Modern, start a game, select a
  piece: the board, its frame, both sides' pieces, the selection ring, hint rings and target dots
  are Modern's; the rest of the screen is unchanged. Repeat with Playful, and both again in Dark
  Mode (Settings app → Developer → Dark Appearance, or the simulator's Features menu).
- Compare with the prototype's designs (`git show e3c0c2b^:checkers/checkers/Modern.html`, open in
  a browser): the look is recognisable; colors differ only where research R4 says.
- **The user approves Modern and Playful**, or names the colors to change; changed colors must
  still pass `US4ContrastTests`.
- Continue a saved game after choosing Playful and relaunching: the board is Playful from the
  first moment.

## 5. Sounds, by ear and on a device (US4, FR-019, SC-003 to SC-005)

- On the Mac: `for f in move capture crowning gameEnd; do afplay
  checkers/checkers/Features/Sound/Sounds/$f.wav; done`. **The user approves the four sounds**, or
  asks for a change to a recipe in `scripts/make-sounds.py` (then run it, listen again, commit).
- On the iPhone, sound on: play against the computer at Easy; each move clicks, each jump of a
  chain clicks twice, crowning chimes, the end of the game plays its phrase; the computer's
  moves sound too, each as its piece appears, with no noticeable delay (SC-004).
- Turn on silent mode: nothing is heard. Silent mode off, start music in another app, return and
  play: the music keeps playing under the game's sounds (SC-005).
- Play a double jump of your own as fast as you can tap: each jump plays its sound, the second
  even if the first has not finished (FR-019); the volume buttons change the game's volume
  (FR-016).
- Settings → Sound effects off: the game is silent.
- The "Sound effects aren't available right now." notice (FR-SND-05) cannot be caused on purpose;
  `US4SoundTests` and its preview cover it. If it ever shows on the device, the next move should
  play its sound and the notice should go.

## 6. Largest text and Dark Mode (FR-026, SC-007)

- Simulator: Settings → Accessibility → Larger Text at the largest size, Dark Mode on. Settings
  and Rules show all their text; the theme previews and Rules pictures stay visible.

## 7. Launch time (SC-008)

```sh
TEST_PLAN=Performance scripts/test.sh
scripts/report-launch.sh .build/TestResults/Performance.xcresult
```

Expected: within the 3.6 s local baseline (`launch-baselines.json`).

Record each result in `checklists/validation.md`.
