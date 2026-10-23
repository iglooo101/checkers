# Validation: Saving and Statistics

Results of the quickstart scenarios ([../quickstart.md](../quickstart.md)) and the measurements the
plan relies on. Development Mac: Intel Core i9-9980HK, 2.4 GHz, Xcode 26.3, Swift 6.2.4.

## Baseline (before any slice code)

- 2026-10-22, branch `006-saving-and-statistics` at `3892d41` (code identical to `main`):
  `scripts/test.sh` passes on the iPhone 17 simulator: **221 tests** (106 app unit tests in 26
  suites, 83 engine tests in 14 suites, 32 UI tests in 11 classes), 11 min 11 s.
- Saved size and speed (research, environment facts): the longest of 200 seeded random games
  played without ending it, 220 turns, is 23,317 bytes as JSON; encode 1.6 ms and decode 1.7 ms
  in Release, 1.7 and 2.0 ms in Debug; a `UserDefaults` write takes 5 µs and a read 1.5 µs.
- Launch arguments in the simulator (research R10, T001), checked with a throwaway UI test that
  was not committed:
  - `-lastGameSetup <hex>` of `{"opponent":"computer","difficulty":"hard","side":"dark"}` makes
    setup preselect Computer, Hard and Dark: launch arguments set stored data. **Pass.**
  - With Medium and Dark stored, `-lastGameSetup none` shows the defaults (Computer, Easy,
    Light), and the next launch without the argument shows Medium and Dark again: a text value
    reads as no data, and the stored value is untouched. **Pass.** So `-savedGame none` can show
    Home without a saved game (T023).

## Implementation measurements

## 1. All blocking tests

## 2. Continue after closing the app

## 3. New game with a saved game

## 4. Record

## 5. A damaged saved game or record

## 6. Accessibility

## 7. CI
