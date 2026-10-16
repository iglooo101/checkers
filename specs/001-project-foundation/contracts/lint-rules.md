# Contract: lint and format rules

What lint and format checks enforce, at which severity, and how exceptions are granted.
Requirements: FR-011, FR-012, FR-013; Constitution I, II, IV, IX; clarifications Q3, Q5.

## Who owns what

| Concern | Tool | Configuration |
|---|---|---|
| Layout: indentation (4 spaces), line length (100), spacing, line breaks, trailing commas | swift-format (bundled with Xcode) | `.swift-format` at the repository root |
| Safety and stack rules | SwiftLint 0.65.1 (build tool plugin) | `.swiftlint.yml` files (see Scope) |

SwiftLint rules that overlap swift-format's layout rules are disabled, so the two tools never
disagree: `trailing_comma`, `opening_brace`, `closing_brace`, `comma`, `colon`, `line_length`,
`trailing_whitespace`, `vertical_whitespace`, `statement_position`, `leading_whitespace`,
`return_arrow_whitespace`, `vertical_parameter_alignment`, `trailing_newline`.

## Errors (fail the build locally and in CI)

| Rule | Flags | Applies to |
|---|---|---|
| `force_unwrapping` | `value!` | app and engine sources, not test targets |
| `force_cast` | `as!` | app and engine sources, not test targets |
| `force_try` | `try!` | app and engine sources, not test targets |
| `implicitly_unwrapped_optional` | `Type!` declarations | app and engine sources, not test targets |
| custom `no_observable_object` | `ObservableObject`, `@Published` | all sources outside the allow-list |
| custom `no_combine` | `import Combine` | all sources outside the allow-list |
| custom `no_legacy_concurrency` | `DispatchQueue`, `OperationQueue`, `Thread` | all sources outside the allow-list |
| custom `no_print` | `print(`, `debugPrint(`, `NSLog(` | app and engine sources; allowed in test targets |
| custom `engine_no_ui_imports` | `import SwiftUI`, `UIKit`, `WebKit` or `Combine` | `CheckersEngine/Sources/` only |

The constitution names `OperationQueue`, `Thread` and `@Published` alongside the constructs listed
in FR-012, so they are enforced too (Constitution I.2, I.3).

## Warnings (reported, never fail CI)

All other enabled SwiftLint rules (SwiftLint's default rule set minus the layout rules above).

## Format check

| Where | Command behavior | Result |
|---|---|---|
| Local build (Run Script phase on the app target) | `swift-format lint` (non-strict) | findings appear as build warnings; no file changes |
| CI | `swift-format lint --strict` | any finding fails `CI gate` |
| On demand | `scripts/format.sh` (`swift-format format --in-place`) | rewrites files to the shared style |

Covered sources: `checkers/checkers`, `checkers/checkersTests`, `checkers/checkersUITests`,
`checkers/CheckersEngine/Sources`, `checkers/CheckersEngine/Tests`.

## Scope

- SwiftLint runs on the app target, both test targets and both `CheckersEngine` targets.
- Test targets relax the force-unwrap family and `no_print` through a nested configuration in
  each test directory; every other rule still applies.

## Allow-list policy

- An exception names specific files, never directories or patterns, and is added to the plan's
  "Lint allow-list" table with its reason in the same change.
- The allow-list starts empty.
