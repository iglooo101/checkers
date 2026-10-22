# Validation: Accessibility

Results of the scenarios in [../quickstart.md](../quickstart.md), recorded during implementation
on the development Mac (Intel Core i9-9980HK, Xcode 26.3, iPhone 17 simulator on iOS 26.3),
starting 2026-10-22.

## Baseline (T001)

| Check | Result | Notes |
|---|---|---|
| `scripts/test.sh` before any slice code | Pass | 130 of 130 (E3's last code commit `e3c0c2b`, CI run 39708152757); no app code has changed since |
| Classic contrast against the dark square `#7a4a24` (research R5) | Measured | Light piece 7.1:1, dark piece 2.3:1, dark-piece outline 1.1:1, selection ring and target dot 1.5:1 (2.6:1 dark), hint ring 4.4:1; crown on a Light king 1.6:1; Light versus Dark pieces 16.1:1 |

## Accessibility audit (T019–T021)

| Check | Result | Notes |
|---|---|---|
| First run, iPhone 17, light, default text size (T019) | 20 problems | Contrast on Home's buttons (system blue), the notice, the placeholder messages, the setup headers and note, the result text and buttons over the board; Dynamic Type on the computer note and the disabled Start |
| Fixes (T020) | Done | Accent and on-accent colors, primary text, opaque result panel, note under the opponent choice (research R6 findings); two system-component issues allow-listed in the plan |
| After the fixes, iPhone 17, light, default text size | Pass | 10 of 10 states; 3 allowed issues logged, all on the Computer setup (disabled Start: contrast and Dynamic Type; the "Side" header at the screen's edge) |
| iPhone SE (3rd generation), Dark Mode, `accessibility-extra-extra-extra-large` (T021) | Pass | 10 of 10 states, no allowed issues; simulator reset to `large` text and light appearance afterwards |

## 1. All automated tests (SC-002 to SC-006)

| Check | Result | Notes |
|---|---|---|
| `scripts/test.sh` (T022, T023) | Pass | 163 of 163 (130 before E7): 73 app unit, 27 UI and 63 engine tests; zero code warnings and zero SwiftLint errors (only Xcode's App Intents metadata notice) |
| `scripts/check-format.sh --strict`, `scripts/tests/run.sh`, `scripts/check-string-catalog.sh` (T022) | Pass | Catalog in sync after `scripts/sync-string-catalog.sh` |
| SC-006: every FRD ID of section 17 named by a test | Pass | `FR-A11Y-01` 9 times, `-02` 4, `-03` 6, `-04` 12, `-05` 2 |

## 2. One story at a time (US1–US5)

| Story | Suites run alone | Result |
|---|---|---|
| US1 | `US1SquareDescriptionTests` (7), `US1SquareLabelUITests` (2) | Pass |
| US2 | `US2VoiceOverPlayTests` (4) | Pass |
| US3 | `US3AnnouncementTests` (6, one over all scripted games) | Pass |
| US4 | `US4ContrastTests` (8 pairs × 2 appearances, crowns) | Pass |
| US5 | `US5AccessibilityAuditUITests` (10) | Pass (see the audit section) |

## 3. Play with VoiceOver (SC-001)

*Open for the user*: XCUITest cannot drive VoiceOver. Play the quickstart §3 game by hand on the
simulator or an iPhone and record it here. The automated tests cover the same paths: double-tap
runs the tap path, focus follows `focusSquare`, and every announcement goes through the
`Announcer` seam.

## 4. Without color (SC-005)

| Check | Result | Notes |
|---|---|---|
| Contrast of every mark (`US4ContrastTests`, T016–T017) | Pass | 3:1 or more for all 8 pairs in both appearances; the Classic colors are now the same in light and dark appearance |
| The board in grayscale on the simulator (T018) | Pass | Two-player game with c3 selected, screenshots in light and dark appearance converted to the Generic Gray profile (`simctl` has no Color Filters switch): Light and Dark pieces, the thick ring on the selected piece, the thin rings on the hinted pieces and the dots on the target squares are all told apart |
| Kings in grayscale (T018) | Pass | `PieceView` kings rendered offscreen and converted the same way: the dark crown on a Light king and the gold crown on a Dark king both stand out. The offscreen renderer leaves out the board's square cells, so kings on the board are checked in the new "Every mark" previews |

## 5. CI

*Pending (T026).*
