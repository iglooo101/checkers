# Validation: Game Experience

Results of the scenarios in [../quickstart.md](../quickstart.md), recorded during implementation
on the development Mac (Intel Core i9-9980HK, Xcode 26.3, iPhone 17 simulator on iOS 26.3),
starting 2026-10-21.

## Baseline (T001–T006)

| Check | Result | Notes |
|---|---|---|
| `scripts/test.sh` after Phases 1–2 | Pass | 75 of 75 tests (app unit and UI, engine), 3 min 37 s; the app still shows the web prototype |
| `scripts/sync-string-catalog.sh` on the current catalog | Pass | "String catalog already matches the last build."; `check-string-catalog.sh` passes afterwards |
| Engine initializers public (T002) | Pass | `GamePositionsTests` failed to compile against the internal initializers, then passed; engine suite 63 of 63 |
| Launch baseline | Recorded | 3.635 s (local Intel simulator, Debug), from `checkers/launch-baselines.json` |

## 1. All automated tests (SC-002)

*Pending (T057).*

## 2. One story at a time (US1–US7)

*Pending (T057).*

## 3. Play a game by hand (SC-001)

*Pending (T057).*

## 4. Screen sizes and text sizes (SC-003, SC-006)

| Check | Result | Notes |
|---|---|---|
| Game screen on iPhone SE (3rd generation), default text (T029) | Pass | `testUS1_boardFitsAndShowsOnlyTheIndicator` and `US2CaptureUITests`: board square, inside the window, squares at least 44 points |
| Game screen on iPhone 17 Pro Max, default text (T029) | Pass | Same tests |
| Game screen on iPhone SE at `accessibility-extra-extra-extra-large`, Dark Mode (T029) | Pass | `US1`, `US2` and `US3` UI tests all pass: board fits with 44-point squares, labels and indicator correct, tap and drag work |
| Previews (T029) | Written | `GameView`, `BoardView`, `PieceView`: start, capture required with notice, selection with targets, Dark at the bottom with kings, `accessibility5`, dark |
| Visual review of the large-text layout | *Pending* | For the hand check in T057 |
| Result panel and dialogs (T035), setup (T046), Home and navigation (T053) | *Pending* | |

## 5. No web content and launch time (SC-005, FR-006)

*Pending (T057).*

## 6. Privacy and the string catalog

*Pending (T057).*

## 7. CI

*Pending (T060).*
