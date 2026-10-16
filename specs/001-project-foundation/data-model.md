# Data Model: Project Foundation

This slice stores no user or game data. Its "entities" are the configuration artifacts that later
slices build on. Each one has a single owner location and a check that keeps it correct.

| Artifact | Location | Defines | Kept correct by |
|---|---|---|---|
| Shared scheme | `checkers/checkers.xcodeproj/xcshareddata/xcschemes/checkers.xcscheme` | Build, run and test actions for the app; references both test plans | CI uses it for every code push |
| Blocking test plan | `checkers/checkers.xctestplan` | `checkersTests`, `checkersUITests` (minus the launch test), `CheckersEngineTests`; Main Thread Checker on | `CI gate` |
| Performance test plan | `checkers/Performance.xctestplan` | `LaunchPerformanceTests` only | CI step that reports timing and fails only if the test errors |
| Launch baseline | shared baseline data in the Xcode project for the local iPhone 17 simulator | Expected cold-launch duration | Local launch test runs |
| Engine package | `checkers/CheckersEngine/Package.swift` and its committed `Package.resolved` | Library `CheckersEngine`, test target `CheckersEngineTests`, platforms iOS 26.2 and macOS 15, Swift 6 mode | `swift test` and the blocking test plan |
| Lint configuration | `.swiftlint.yml` files (see `contracts/lint-rules.md`) | Rule set, severities, custom rules | Build tool plugin on every build |
| Format configuration | `.swift-format` (repository root) | Layout rules | Build phase (warn), CI (fail) |
| Lint allow-list | plan's "Lint allow-list" table and matching `.swiftlint.yml` exclusions | Files exempt from a custom rule, with reasons | Review; starts empty |
| Privacy manifest | `checkers/checkers/PrivacyInfo.xcprivacy` | No tracking, no tracking domains, no collected data, no required-reason APIs yet | US5 manifest test (T042); archive privacy report in E8 (#177) |
| String catalog | `checkers/checkers/Localizable.xcstrings` | Every user-facing string in Swift code | `scripts/check-string-catalog.sh` in CI |
| Log categories | `checkers/checkers/Support/Logging.swift` | Subsystem (bundle identifier) and one category per feature, starting with `app` | Review; `no_print` lint rule |
| CI workflow | `.github/workflows/ci.yml` | Jobs `changes`, `build-and-test`, `CI gate` (see `contracts/ci-gate.md`) | Its own runs |
| Branch protection | GitHub settings for `main` | Required check `CI gate`, administrators included, no pull requests | Probe push in quickstart |

## Lifecycle notes

- **Privacy manifest**: gains the user-defaults entry (reason `CA92.1`) in the change that first
  uses `UserDefaults` or `@AppStorage` (#71 or #140).
- **Log categories**: each new feature adds its own category in the same file.
- **Lint allow-list**: an entry is added only with a reason recorded in the plan of the slice
  that needs it.
- **Launch baseline**: re-recorded only when a deliberate change to launch work is accepted.
