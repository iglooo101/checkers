# Quickstart: validating the game experience

Run these scenarios to prove the slice works. Each names the user story or success criterion it
validates. Commands run from the repository root. Texts and identifiers are in
[contracts/screens.md](contracts/screens.md); interaction rules in
[contracts/game-session.md](contracts/game-session.md).

## Prerequisites

- Xcode 26.3 with the iPhone 17 simulator on iOS 26.3 (as for E1 and E2).
- For SC-003, two more simulators on iOS 26.3: iPhone SE (3rd generation), the smallest supported
  screen, and iPhone 17 Pro Max, the largest:
  `xcrun simctl create "iPhone SE (3rd generation)" com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation com.apple.CoreSimulator.SimRuntime.iOS-26-3`.

## 1. All automated tests (SC-002)

```sh
scripts/test.sh
```

Expected: the blocking test plan passes with zero warnings and zero SwiftLint errors: unit tests
for `GameSession`, `BoardLayout`, `AppRouter` and the setup store, the UI tests of every story,
and the engine tests. Every in-scope FRD ID in the spec's traceability table appears in at least
one test name with its story ID:

```sh
grep -rhoE 'FR-(NAV|SETUP|GAME|MOVE|AID|CHAIN|END|UNDO|SND|PLAT)-[0-9]+' checkers/checkersTests checkers/checkersUITests | sort -u
```

## 2. One story at a time (US1–US7)

```sh
source scripts/lib.sh
xcodebuild test "${XCODEBUILD_FLAGS[@]}" -only-testing:checkersTests/US1TwoPlayerMoveTests -only-testing:checkersUITests/US1TwoPlayerMoveUITests
```

Repeat with the US2–US7 suites (names in `tasks.md`). Expected: each story's unit and UI tests
pass on their own.

## 3. Play a game by hand (SC-001)

Launch the app on the iPhone 17 simulator and play a two-player game to the end:

- Home shows New game, Statistics, Rules and Settings (US1).
- New game → Two players → Start shows the board with Light at the bottom and "Light to move".
- Moves by tap and by drag land instantly with no animation (SC-004); an illegal drop returns the
  piece (US3).
- After `c3–d4, f6–e5`, the indicator reads "Light to move · capture required", d4 is the only
  hinted piece, and tapping e3 shows "A capture is required." (US2).
- A multi-jump keeps the piece selected between jumps; a man reaching the far row shows a crown.
- Undo steps back to the start and is then unavailable (US5).
- Resign asks first; the result panel shows the outcome over the final board; Play again starts a
  fresh game (US4).
- Choosing Computer in setup shows difficulty, side and the note, and Start is disabled; relaunching
  keeps the choices (US6).
- Rules and Settings from the menu return to the same position; Home asks "Leave this game?" (US7).

Every move took at most two taps or one drag per jump.

## 4. Screen sizes and text sizes (SC-003, SC-006)

On iPhone SE (3rd generation) and iPhone 17 Pro Max, with Settings → Accessibility → Display &
Text Size → Larger Text at the largest size, and in Dark Mode:

- The whole board is visible without scrolling; squares are at least 44 points wide.
- The turn indicator, notice, menu, setup choices, dialogs and result panel show their full text.

In Xcode, every new view's previews render in light, dark and `accessibility5`.

## 5. No web content and launch time (SC-005, FR-006)

```sh
find checkers/checkers -name '*.html' -o -name '*.wav' | wc -l          # expected: 0
grep -rn 'WebKit\|WKWebView' checkers/checkers | wc -l                   # expected: 0
TEST_PLAN=Performance scripts/test.sh && scripts/report-launch.sh .build/TestResults/Performance.xcresult
```

Expected: no HTML, sound or web-view code remains, and cold launch is no slower than the recorded
baseline in `checkers/launch-baselines.json`.

## 6. Privacy and the string catalog

```sh
scripts/check-string-catalog.sh checkers/checkers/Localizable.xcstrings .build/DerivedData
```

Expected: the catalog is up to date (every new string present, the old picker strings gone), and
`PrivacyManifestTests` confirms the manifest declares exactly the user-defaults API with reason
`CA92.1` and still no tracking or collected data.

## 7. CI

Push the branch. Expected: `CI gate` is green.
