# Quickstart: validating the project foundation

Run these scenarios to prove the slice works end to end. Each names the user story and
requirements it validates. Commands run from the repository root unless noted.

## Prerequisites

- Xcode 26.3 selected (`xcode-select -p` points at it) with an iPhone 17 simulator on iOS 26.3.
- Network access for the first build, so Swift Package Manager can fetch the SwiftLint plugin.
- In Xcode, trust the SwiftLint plugin once when prompted. Command-line builds pass
  `-skipPackagePluginValidation`, which the scripts below already do.

## 1. Tests run locally (US1: FR-001 to FR-003)

```sh
scripts/test.sh
```

Expected: unit, UI and engine tests run on the iPhone 17 simulator and the run passes.
Then add `#expect(Bool(false))` to any unit test and run again: the run fails and names that test.
Revert the change.

## 2. Engine module on its own (US4: FR-004)

```sh
(cd checkers/CheckersEngine && swift test)
```

Expected: `CheckersEngineTests` pass on the Mac without building the app. Adding
`import SwiftUI` to a file under `CheckersEngine/Sources/` makes the build report the
`engine_no_ui_imports` lint error. Revert.

## 3. Compiler and lint rules (US3: FR-010 to FR-012)

Build the app in Xcode or with `scripts/test.sh`. Expected: 0 compiler warnings.

Add each of these to a file in `checkers/checkers/`, one at a time, and build:

| Probe | Expected |
|---|---|
| `let x: Int? = 1; _ = x!` | `force_unwrapping` error |
| `final class Model: ObservableObject {}` | `no_observable_object` error |
| `DispatchQueue.main.async {}` | `no_legacy_concurrency` error |
| `print("hello")` | `no_print` error |
| `print("hello")` inside a test file | accepted |

Revert each probe.

## 4. Formatting (US3: FR-013)

Indent a line in any Swift file by 3 spaces and build in Xcode. Expected: a format warning names
the file and the file is unchanged. Run `scripts/format.sh`: the indentation is fixed.

## 5. CI gate (US2: FR-005 to FR-009; contract: `contracts/ci-gate.md`)

On a scratch branch pushed to GitHub:

| Push | Expected `CI gate` |
|---|---|
| A failing unit test | failure, log names the test |
| A compiler warning (for example an unused variable) | failure, log names the warning |
| A lint error (for example a force unwrap) | failure, log names the rule |
| An unformatted line | failure, log names the file |
| A change to a `.md` file only | success within 2 minutes, no build step ran |
| A change to `.md` and a Swift file | full run |

Then on `main`:

- Push a commit whose check has not passed: the push is rejected, even as the repository owner.
- Fast-forward `main` to a branch commit that passed and push: accepted, no pull request.

Delete the scratch branch afterwards.

## 6. Privacy, logging, localization and platform (US5: FR-014 to FR-018)

- **Privacy**: Product › Archive, then generate the privacy report in the Organizer. Expected: no
  tracking, no tracking domains, no collected data types.
- **Localization**: remove the `Screen` entry from `Localizable.xcstrings` and run
  `scripts/check-string-catalog.sh` after a build. Expected: it fails and names the missing key.
  Revert.
- **Logging**: temporarily rename `Play.html` in a debug run. Expected: the console shows an error
  from subsystem `Hussein-Helmy.checkers`, category `app`. Revert.
- **Platform**: run on the iPhone 17 simulator and rotate to landscape. Expected: the app stays in
  portrait. In the project settings, the supported destinations list iPhone only.

## 7. Cleanup and launch baseline (US6: FR-019, FR-020)

```sh
git ls-files | grep -E 'Item\.swift|Assets\.xcassets/CheckersApp\.swift'
```

Expected: no output.

Run the `Performance` test plan from Xcode (Product › Test Plan › Performance, then Test).
Expected: a cold-launch duration is reported against the recorded baseline. In CI, the same
number appears in the job summary, and a slow result does not fail `CI gate`.

## 8. Existing screens unchanged (FR-021, SC-007)

Run the app on the iPhone 17 simulator. Expected: Classic, Modern, Playful and Play load, and the
Play screen accepts a move.
