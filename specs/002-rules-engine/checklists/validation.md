# Validation: Rules Engine

Results of the scenarios in [../quickstart.md](../quickstart.md), recorded during implementation
on the development Mac (Intel Core i9-9980HK, Xcode 26.3, Swift 6.2.4), 2026-10-21. Engine tests
run as a Debug build.

## Baseline (T001, T002)

| Check | Result | Notes |
|---|---|---|
| `(cd checkers/CheckersEngine && swift test)` before any slice code | Pass | 1 test (`SideTests`) in 1 suite; 9.5 s wall time including the build |
| `swift test` runs SwiftLint | **No** | The SwiftLint build tool plugin compiles, but its prebuild command does not run under `swift build`/`swift test`: a force unwrap in `Sources/Side.swift` builds cleanly. Engine lint runs only in the Xcode build (`scripts/test.sh`, CI). Quickstart §1, §6 and §7 updated |
| Xcode build, force unwrap in `Sources/Side.swift` | Fails (expected) | `error: Force Unwrapping Violation … (force_unwrapping)`, `TEST BUILD FAILED` |
| Xcode build, force unwrap in `Tests/CheckersEngineTests/SideTests.swift`, with the new `Tests/.swiftlint.yml` | Passes (expected) | `TEST BUILD SUCCEEDED` |
| Same, without `Tests/.swiftlint.yml` (control) | Fails | `force_unwrapping` error in `SideTests.swift`, so the new file is what relaxes the rule |

## Test-first record

| Story | Observed before implementing | After |
|---|---|---|
| Foundation (T003–T006) | Failed to compile: `Square`, `Piece`, `BoardGeometry` not found | 20 tests pass |
| US1 (T013) | Failed to compile: `GameState` not found | 26 tests pass |
| US2 (T017) | 9 issues: no jumps, no captures required, king moves missing | 34 tests pass |
| US3 (T020–T022) | 19 issues; reference counts pass at depths 1–6 and fail at depth 7, as research R1 predicted | 44 tests pass |
| US4 (T025) | Failed to compile: `history`, `noProgressCount`, `resign` not found | 56 tests pass |
| US5 (T029–T031) | Failed to compile: `undo`, `canUndo` not found | 63 tests pass |

## 1. Whole engine suite on the Mac (SC-005)

| Check | Result | Notes |
|---|---|---|
| `(cd checkers/CheckersEngine && swift test)` | Pass | 63 tests in 11 suites, zero compiler warnings; 24.3 s test time, 30.3 s wall (21–24 s across runs). Target under 60 s (R12): met |
| SwiftLint on engine sources and tests (run directly, as the plugin does) | Pass | No violations |
| `scripts/check-format.sh --strict` | Pass | |

## 2. One story at a time (US1–US5)

| Filter | Result |
|---|---|
| `swift test --filter US1` | 6 tests pass |
| `swift test --filter US2` | 8 tests pass |
| `swift test --filter US3` | 8 tests pass |
| `swift test --filter US4` | 12 tests pass |
| `swift test --filter US5` | 6 tests pass |

## 3. Reference move counts and speed (SC-002, SC-004)

| Check | Result | Notes |
|---|---|---|
| Counts for 1–7 turns: 7, 49, 302, 1,469, 7,361, 36,768, 179,740 | Pass | Match OEIS A133046 and Aart Bik's page (R1) |
| 6-turn count under 10 s | Pass | 5.0 s alone, 6.4 s while the other suites run in parallel; Debug build on the Intel Mac. Margin about 2× |

## 4. Random games (SC-003)

| Check | Result | Notes |
|---|---|---|
| 1,000 seeded games end within the turn bound, keep every invariant after every step, and undo exactly from the start of their final turn back to `GameState()` | Pass | 13.9 s |
| Random play reaches wins by no moves left, draws by repetition and draws by no progress | Pass | Checked by the same test |

## 5. Requirement coverage (SC-001)

| Check | Result | Notes |
|---|---|---|
| FRD IDs named by engine tests | Pass | Exactly the 21 IDs: FR-RULE-01 to 07, FR-CHAIN-01 to 03, FR-END-01 to 05, FR-UNDO-01, 02, 05, 06, 07, FR-SETUP-06 |

## 6. In the app's test plan and CI

| Check | Result | Notes |
|---|---|---|
| `scripts/test.sh` | Pass | `TEST SUCCEEDED`; 72 of 72 tests (63 engine, 9 app and UI); 1 min 15 s; no SwiftLint violations |
| Engine tests in the result bundle | Pass | `xcresulttool` lists `CheckersEngineTests` |
| `scripts/tests/run.sh` | Pass | All script tests, including the lint rules after the `identifier_name` change |
| `CI gate` on the branch | Pass | Run 39680886427 on `cac611b`: 63 engine tests in 11 suites passed in 21.6 s on the runner's simulator (SC-004 6.7 s), `TEST SUCCEEDED`; US1 run 39678699051 also green |

## 7. Engine stays UI-free (SC-005, FR-025)

| Check | Result | Notes |
|---|---|---|
| `import SwiftUI` in `Sources/Piece.swift`, Xcode build | Fails (expected) | `Engine stays UI-free Violation`, `TEST BUILD FAILED`; reverted |
