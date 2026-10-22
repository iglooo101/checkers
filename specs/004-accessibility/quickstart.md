# Quickstart: validating accessibility

Run these scenarios to prove the slice works. Each names the user story or success criterion it
validates. Commands run from the repository root. Texts are in
[contracts/announcements.md](contracts/announcements.md).

## Prerequisites

- As for E3: Xcode 26.3, the iPhone 17 simulator on iOS 26.3, and the iPhone SE (3rd generation)
  simulator for small-screen checks (`specs/003-game-experience/quickstart.md`).

## 1. All automated tests (SC-002 to SC-006)

```sh
scripts/test.sh
```

Expected: the blocking test plan passes, including the square-description and announcement tests
over scripted games, the contrast test and the accessibility audit of every screen. Every FRD ID of
section 17 is named by a test:

```sh
grep -rhoE 'FR-A11Y-0[1-5]' checkers/checkersTests checkers/checkersUITests | sort -u
```

## 2. One story at a time (US1–US5)

```sh
source scripts/lib.sh
xcodebuild test "${XCODEBUILD_FLAGS[@]}" -only-testing:checkersTests/US1SquareDescriptionTests
```

Repeat with each story's suites (names in `tasks.md`). Expected: each passes on its own.

## 3. Play with VoiceOver (SC-001)

On the iPhone 17 simulator, turn on VoiceOver (Settings → Accessibility → VoiceOver, or the
Accessibility Shortcut), then using only VoiceOver gestures:

- Swipe across the board: squares are read in on-screen order, light squares skipped, with states
  such as "c3, Light man, can move".
- Double-tap c3, swipe to d4 ("d4, empty, legal target") and double-tap: you hear "Light c3 to d4.
  Dark to move." and focus is on d4.
- Play `f6–e5`; double-tap e3: "A capture is required."; capture d4×f6: "Light captures e5. Dark to
  move, capture required."
- Play a double jump: after the first jump "… Jump again." with focus on the landing square.
- Undo, then resign from the game menu and hear the result.

Record the run in `checklists/validation.md`.

## 4. Without color (SC-005)

Turn on Settings → Accessibility → Display & Text Size → Color Filters → Grayscale on the
simulator, in light and dark appearance. Expected: Light and Dark pieces, kings (crown), the
selected piece (thick ring), hinted pieces (thin ring) and target squares (dot) are all told apart.
The contrast test in §1 checks the numbers.

## 5. CI

Push the branch. Expected: `CI gate` is green.
