# Validation: Settings, Themes, Sound and Rules

Results of the quickstart scenarios ([../quickstart.md](../quickstart.md)) and the measurements the
plan relies on. Development Mac: Intel Core i9-9980HK, 2.4 GHz, Xcode 26.3, Swift 6.2.4.

## Baseline (before any slice code)

- 2026-10-24, branch `007-settings-themes-sound-and-rules` at `0c898e0` (no slice code yet; app
  code identical to `main`): `scripts/test.sh` passes on the iPhone 17 simulator: **264 tests**
  (133 app unit tests in 31 suites, 86 engine tests in 15 suites, 45 UI tests in 15 classes),
  14 min 53 s.

## Measurements from the plan (2026-10-23, research.md)

Taken with throwaway programs outside the repository while planning; the implementation
measurements below check the ones the code depends on.

- **Environment facts**: `GameSession(` appears 46 times in the app and its tests, so new
  initializer parameters get defaults; reading the three settings from `UserDefaults` takes
  2.4 µs, so they are read on the main actor before the first frame (R1); Python 3.14.3 on the Mac
  and Python 3 on CI's runners for the sound script.
- **R4, contrast** (WCAG, the 8 pairs of `US4ContrastTests`, the target blended at its alpha over
  the dark square, light and dark appearance): every pair passes 3:1 in all three themes.
  Weakest pair: Classic the target at 3.64:1 (E7, unchanged), Modern the target at 5.64:1,
  Playful the light piece on the dark piece at 4.16:1. The prototype's own colors fail: Modern's
  dark piece on its square 1.11:1, Playful's pieces on their squares 1.36:1 and 1.67:1 and
  against each other 2.28:1.
- **R6, sounds** (the prototype of `scripts/make-sounds.py`, seed 20261023): `move` 0.12 s,
  `capture` 0.22 s, `crowning` 0.45 s, `gameEnd` 1.2 s (FR-019: at most 0.5 s and 2 s); 10.6,
  19.4, 39.7 and 105.9 KB (176 KB in all); RMS −21.2, −21.8, −19.1 and −18.2 dBFS; two runs give
  byte-identical files; generation takes 0.4 s.
- **R7, players** (on the Mac, the closest proxy for an iPhone): loading and preparing the four
  `AVAudioPlayer`s takes 107 ms the first time, and each `play()` call 11–69 ms, so both run in
  the `SoundBank` actor, off the main actor. The actor compiles in Swift 6 with complete strict
  concurrency and no warnings.

## Implementation measurements

- Setup and Foundational (T001–T005), 2026-10-24: before T004 the new tests failed to compile
  (`build-for-testing`: no `Log.settings`, `Log.sound`). With it, `SettingsStoreTests`,
  `LoggingTests` and `PrivacyManifestTests` pass (12 tests), and all 141 app unit tests ran.
  Found on the way: `UserDefaults` skips a write that equals the stored value, and the number 0
  equals `false`, so the unreadable-value test removes the key before storing the bad value. The
  store reads only real booleans: 0, 1 and 3.5 are unreadable, though Foundation would convert
  them.
- US1 (T006–T010), 2026-10-24: before T009 the new tests failed to compile (no
  `GameSession.settings`). With T009 and T010, US1's independent test set passes on the iPhone 17
  simulator: 19 unit tests in 4 suites (`US1SettingsTests`, `US7NavigationTests`,
  `LocalizationTests`, `US3HintsDragTests`, unchanged) and 9 UI tests (`US1SettingsUITests`,
  `US7NavigationUITests`, `testUS5_auditSettings`). **Research R10 holds in the simulator**:
  `testUS1_launchArgumentSetsHints` launches with `-moveHints <false/>` and Settings shows hints
  off. A form's switch fills its row, so `setSwitch` taps near the trailing edge; `@Bindable`
  cannot bind through the router's `let settings`, so `SettingsView` binds to the settings object
  in its body. CI run 40069158202 on `5ee5297` (Setup, Foundational and US1) passed: `CI gate`
  green with both jobs.
- US2 (T011–T015), 2026-10-24: before T015 the new tests failed to compile (no `RulesContent`).
  With T014 and T015, US2's independent test set passes on the iPhone 17 simulator: 9 unit tests
  in 3 suites (`US2RulesTests`, `US7NavigationTests`, `LocalizationTests`) and 8 UI tests
  (`US2RulesUITests`, `US7NavigationUITests`, `testUS5_auditRules`). `US2RulesTests` reads
  contracts/rules-content.md itself and requires every title, text and picture description to
  match it word for word, so the contract stays the one source; `LocalizationTests` takes the
  Rules strings from `RulesContent`. Section texts: 364 words; descriptions: 156. CI run
  40071432056 on `4abbe44` passed every test, but `build-and-test` reached its 30-minute limit
  during "Launch timing" (25 minutes of build and tests against US1's 19: US2's UI tests added
  about 50 s, and the runner was about 15% slower), so `CI gate` failed. With the limit at 45
  minutes (#204, T036), CI run 40116301945 on `3b8ba4d` passed: `build-and-test` 24 minutes,
  `engine-strength` 7.
- US3 (T016–T020), 2026-10-24: written on a local work branch and brought onto the slice branch
  in one commit. The three themes' colors are namespaced asset folders (`Classic/`, `Modern/`,
  `Playful/`); `US4ContrastTests` passes its 8 pairs for every theme in light and dark, and
  `US3ThemeTests` pins Classic to E7's values and Modern and Playful to research R4's table.
  `testUS5_auditSettings` failed with the theme rows as an inline picker: "Contrast failed" on
  the Classic and Playful rows whichever theme was chosen. A probe found each picker row's label
  merged into one text element covering the preview and the name (142 × 72 points), so the
  audit measured the board's squares as the name's colors; containing the row's children
  exposed the preview and its crowns as elements and failed "Element has no description"
  instead. As one button per theme (selected trait, checkmark hidden from VoiceOver) the name is
  its own text element (54 × 20 points) and every audit type passes (research R11, "Found in
  US3"). `scripts/test.sh` passes on the iPhone 17 simulator: **294 tests** (155 app unit tests
  in 35 suites, 86 engine tests, 53 UI tests), formatting strict and the string catalog in sync.
  CI run 40121012315 on `20096e7` passed: `build-and-test` 27 minutes, `engine-strength` 5.
- US4 (T022–T027), 2026-10-24: tests first. Before T025 `test-make-sounds.sh` failed (no script,
  no files); before T026–T027 the unit tests failed to compile (no `SoundEffect`,
  `RecordingSoundPlayer`). **The sounds** (`scripts/make-sounds.py`, 0.39 s; a second run writes
  byte-identical files):

  | File | Length | Size | Peak |
  |---|---|---|---|
  | `move.wav` | 0.120 s | 10,628 bytes | −3.0 dBFS |
  | `capture.wav` | 0.220 s | 19,448 bytes | −3.0 dBFS |
  | `crowning.wav` | 0.450 s | 39,734 bytes | −6.0 dBFS |
  | `gameEnd.wav` | 1.200 s | 105,884 bytes | −6.0 dBFS |

  Research R6's lengths and sizes, reproduced. The check names a file with one sample changed by
  two steps, a missing file and a longer file. Found on the way: the drafted silent-actions test
  tapped c3 after a refused drop, which deselects it (the drop leaves it selected), so it now taps
  only the target; E3's `NoWebContentTests` allowed no `.wav` in the bundle (the prototype had a
  `move.wav`), and now requires exactly the four `SoundEffect` files; the Sound section moved the
  Game section's header and footer to the bottom edge, where the Settings audit reported them as
  "partially unsupported" Dynamic Type, the edge-cut report known from setup. On screen at the
  largest size both scale (the footer wraps over six lines), so the audit's allow-list gained a
  Settings row (plan, "Audit allow-list"). Every `SoundBank` test passed in the simulator,
  including preparing the four bundled files. `scripts/test.sh` with warnings as errors passes:
  **309 tests** (168 app unit tests in 37 suites, 86 engine tests, 55 UI tests), the script tests,
  formatting strict and the string catalog in sync.

## 1. All blocking tests (SC-001 to SC-003, SC-006, SC-007, SC-009)

## 2. Move hints (US1, SC-001)

## 3. Rules (US2, SC-006)

## 4. Themes, visual review (US3, FR-012, SC-002)

## 5. Sounds, by ear and on a device (US4, FR-019, SC-003 to SC-005)

## 6. Largest text and Dark Mode (FR-026, SC-007)

## 7. Launch time (SC-008)
