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
| Result panel and resign alert on iPhone SE at `accessibility-extra-extra-extra-large`, Dark Mode (T035) | Pass | `US4GameEndUITests` passes: alert buttons, result text and both result buttons found and tapped; previews for all six results at `accessibility5` and dark |
| Resign confirmation as an alert (T035) | Changed | On iOS 26 a confirmation dialog from a toolbar item shows as a popover without Cancel (*measured*), so resign uses an alert; research R10 updated |
| Setup on iPhone SE at `accessibility-extra-extra-extra-large`, Dark Mode (T046) | Pass | `US6SetupUITests` passes after scrolling: the form is taller than the screen at this size and creates rows as they scroll into view, so the test scrolls to each choice; it also passes at default size on iPhone 17 |
| Home, navigation and placeholders on iPhone SE at `accessibility-extra-extra-extra-large`, Dark Mode (T053) | Pass | `US7NavigationUITests` (menu, Rules/Settings return, leave confirmation, placeholders, largest text size) and `US5UndoUITests` pass |
| Largest text size from a launch argument on iPhone 17 (T049) | Pass | `testUS7_largestTextSize`: Home, setup, the game menu and the result panel buttons all hittable; board inside the window |

## 5. No web content and launch time (SC-005, FR-006)

*Pending (T057).*

## 6. Privacy and the string catalog

| Check | Result | Notes |
|---|---|---|
| String extraction (T054) | Fixed | From a `switch` expression with an optional result the compiler extracted only one literal (*measured* in the `.stringsdata`): `GameText.result` and `PlaceholderText` now use explicit `return`s, and all 9 strings are extracted |
| Old picker strings (T055) | Removed | `Classic`, `Modern`, `Play`, `Playful`, `Screen` are gone; untranslated keys that are no longer extracted are dropped by `xcstringstool sync` |
| `check-string-catalog.sh` after T055 | Pass | "String catalog is up to date." |
| `PrivacyManifestTests` (T041) | Pass | Exactly the user-defaults API, reason `CA92.1`; no tracking or collected data |

*Full scenario pending (T057).*

## 7. CI

*Pending (T060).*
