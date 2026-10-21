# Validation: Rules Engine

Results of the scenarios in [../quickstart.md](../quickstart.md), recorded during implementation
on the development Mac (Intel Core i9-9980HK, Xcode 26.3, Swift 6.2.4).

## Baseline (T001, T002, 2026-10-21)

| Check | Result | Notes |
|---|---|---|
| `(cd checkers/CheckersEngine && swift test)` before any slice code | Pass | 1 test (`SideTests`) in 1 suite; 9.5 s wall time including the build |
| `swift test` runs SwiftLint | **No** | The SwiftLint build tool plugin compiles, but its prebuild command does not run under `swift build`/`swift test`: a force unwrap in `Sources/Side.swift` builds cleanly. Engine lint runs only in the Xcode build (`scripts/test.sh`, CI). Quickstart §1, §6 and §7 updated |
| Xcode build, force unwrap in `Sources/Side.swift` | Fails (expected) | `error: Force Unwrapping Violation … (force_unwrapping)`, `TEST BUILD FAILED` |
| Xcode build, force unwrap in `Tests/CheckersEngineTests/SideTests.swift`, with the new `Tests/.swiftlint.yml` | Passes (expected) | `TEST BUILD SUCCEEDED` |
| Same, without `Tests/.swiftlint.yml` (control) | Fails | `force_unwrapping` error in `SideTests.swift`, so the new file is what relaxes the rule |

## 1. Whole engine suite on the Mac (SC-005)

*Pending (T034).*

## 2. One story at a time (US1–US5)

*Pending (T034).*

## 3. Reference move counts and speed (SC-002, SC-004)

*Pending (T034).*

## 4. Random games (SC-003)

*Pending (T034).*

## 5. Requirement coverage (SC-001)

*Pending (T034).*

## 6. In the app's test plan and CI

*Pending (T034).*

## 7. Engine stays UI-free (SC-005, FR-025)

*Pending (T034).*
