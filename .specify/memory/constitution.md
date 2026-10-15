# Checkers Constitution

## Core Principles

### I. Native & Modern Apple Stack

1. All UI MUST be built in SwiftUI. UIKit MAY be used only through `UIViewRepresentable` or
   `UIViewControllerRepresentable` when SwiftUI cannot do the job, and the plan MUST record why.
   Rendering app UI as web content (bundled HTML in a `WKWebView` or SwiftUI `WebView`) counts as
   non-SwiftUI UI and requires the same written justification.
2. App state MUST use the Observation framework (`@Observable`). New `ObservableObject`,
   `@Published` or Combine code MUST NOT be added unless the plan justifies it (for example, an
   Apple API that is only exposed as a Combine publisher).
3. All asynchronous work MUST use Swift Concurrency (`async`/`await`, `Task`, actors,
   `@MainActor`). New APIs MUST NOT take completion-handler parameters. `DispatchQueue`,
   `OperationQueue` and `Thread` MUST NOT appear in new code except inside an adapter that wraps a
   legacy or system callback API.
4. Apple frameworks (SwiftData/Core Data, URLSession, Swift Testing, OSLog, MetricKit, Keychain
   Services) MUST be used in preference to third-party code (see Principle VIII).

**Verified by**: code review; SwiftLint custom rules that flag `ObservableObject`, `import Combine`
and `DispatchQueue` outside files allow-listed in the plan; the plan's Constitution Check.

**Rationale**: One modern, first-party stack keeps the codebase consistent with Apple's direction
and lets the compiler enforce concurrency safety.

### II. Feature-Based Architecture & Modularity

1. Code MUST be organized by feature, with each feature owning its Views, Models and Services. A
   feature SHOULD live in a local Swift Package module when its logic needs tests independent of
   the app target or is used by two or more features.
2. Views MUST be thin and declarative. They MUST NOT contain business rules (game rules,
   validation, scoring, persistence writes, networking). Views MAY read data with SwiftData
   `@Query`; all writes and logic go through an `@Observable` model or a service that is testable
   without UI.
3. Dependencies on services MUST be injected through protocols, via the SwiftUI environment or an
   initializer. Stateful services MUST NOT be singletons (`static let shared`). System singletons
   (`URLSession.shared`, `FileManager.default`, `UserDefaults.standard`) MAY be used only behind an
   injected protocol.
4. Types MUST be structs or enums by default. Classes are allowed only for identity or shared
   mutable state (which includes `@Observable` models and SwiftData `@Model` types).
5. A generic or shared abstraction layer MUST NOT be introduced until three concrete cases exist.
   Dependency-injection protocols (one live and one fake conformance) are exempt.

**Verified by**: code review against the plan's project structure; grep for `static let shared`
on non-system types; unit tests that build models and services without instantiating any view.

**Rationale**: Logic kept out of views is cheap to test, and protocol seams make fakes trivial.

### III. Test-First Quality (NON-NEGOTIABLE)

1. Tests for business logic MUST be written before the implementation and MUST be observed failing
   before implementation begins. In `tasks.md`, each test task MUST come before the
   implementation tasks it covers.
2. Unit and integration tests MUST use Swift Testing (`@Test`, `#expect`, `#require`). XCTest and
   XCUITest are allowed only for UI flows and performance metrics.
3. Every user story in a spec MUST have at least one automated acceptance test. Each acceptance
   test MUST name its story ID (for example `US1`) in its display name or tag.
4. Network and persistence layers MUST be tested against protocol-based fakes. Unit tests MUST NOT
   touch the live network. SwiftData tests MUST use an in-memory `ModelConfiguration`.
5. CI MUST block a merge on any failing test, any compiler warning, or any SwiftLint error.
6. This principle overrides any template text that marks tests as optional.

**Verified by**: git history shows test code committed at or before the implementation it
covers; a story-ID-to-test mapping in `tasks.md`; CI status checks.

**Rationale**: Tests written first define behavior and catch regressions before they ship. A
checkers rules engine is especially error-prone without them (mandatory captures, multi-jump
chains, kinging).

### IV. Safety & Correctness

1. Code outside test targets MUST NOT contain force unwraps (`!`), force casts (`as!`),
   `try!`, or implicitly unwrapped optionals.
2. Errors MUST be modeled as typed `Error` enums per feature, and SHOULD use typed throws
   (`throws(FeatureError)`) at module boundaries. Every `catch` MUST handle, map, or surface the
   error. Empty `catch` blocks are forbidden, and `try?` MUST NOT discard an error whose failure
   changes user-visible state.
3. Every error reachable by the user MUST be shown in a clear state with a recovery action
   (retry, dismiss, or an alternate path).
4. The project MUST build in Swift 6 language mode with complete strict concurrency checking and
   zero warnings. Data races are compile errors, not runtime bugs. `@unchecked Sendable` and
   `nonisolated(unsafe)` MUST NOT be used without a documented justification in the plan.

**Verified by**: SwiftLint `force_unwrapping`, `force_cast`, `force_try` and
`implicitly_unwrapped_optional` rules at error severity; `SWIFT_TREAT_WARNINGS_AS_ERRORS = YES`
in CI; tests for each error path.

**Rationale**: Crashes and silent failures are the most damaging defects a user can see. The
compiler can rule out a whole class of them.

### V. User Experience & Accessibility

1. UI MUST follow the Apple Human Interface Guidelines and SHOULD use system components and SF
   Symbols. Colors MUST be semantic system colors or asset-catalog colors with light and dark
   variants. Hard-coded RGB values in views are forbidden.
2. Every screen MUST support Dynamic Type through `accessibility5` without truncating or
   overlapping essential content. Every interactive element MUST have a meaningful VoiceOver label,
   and game state (for example piece, square, whose turn) MUST be announced. Every screen MUST
   render correctly in Dark Mode, and animations MUST respect `accessibilityReduceMotion`.
3. Every view that depends on asynchronous data MUST model and render explicit loading, empty,
   error and content states.
4. All user-facing strings MUST be localizable through String Catalogs (`.xcstrings`) from the
   first commit. No user-facing text may be built by concatenating strings.

**Verified by**: `#Preview` variants at `.accessibility5`, Dark Mode, and each async state; an
XCUITest that runs `XCUIApplication.performAccessibilityAudit()` on every screen; String Catalog
build warnings treated as errors.

**Rationale**: Accessibility and localization cost little up front and a great deal to retrofit.

### VI. Privacy & Security

1. A feature MUST collect only the data it needs, as listed in its spec. Every permission request
   MUST have an `Info.plist` purpose string and MUST be triggered by the user action that needs it,
   never at launch.
2. Secrets, tokens and credentials MUST be stored in the Keychain. They MUST NOT be stored in
   `UserDefaults`, plists, source code or build settings.
3. `PrivacyInfo.xcprivacy` MUST accurately declare collected data types, tracking status and
   required-reason APIs (including `UserDefaults`) and MUST be updated in the same change that
   alters them. Every third-party SDK MUST ship its own privacy manifest and justify its data
   collection in the plan.
4. All network traffic MUST use HTTPS with App Transport Security enabled. ATS exceptions MUST NOT
   be added without documented approval recorded in the plan.

**Verified by**: Xcode privacy report generated from each release archive; grep for
`NSAppTransportSecurity` exceptions; code review of storage calls.

**Rationale**: User trust and App Store review both depend on accurate, minimal data handling.

### VII. Performance

1. A release build MUST reach first frame from a cold launch in under 400 ms on an iPhone from the
   last two hardware generations.
2. Scrolling and animations MUST hold the display's native frame rate (60 fps, or 120 fps on
   ProMotion), measured as a hitch-time ratio under 5 ms/s.
3. The main thread MUST NOT perform file, database or network I/O or heavy computation (such as
   game AI search). Because the app target defaults to `MainActor` isolation, such work MUST live
   in `nonisolated` types, actors, or `@concurrent` functions.
4. Optimizations MUST be preceded by an Instruments profile, and performance claims in plans or
   PRs MUST cite a measurement.

**Verified by**: `XCTApplicationLaunchMetric` and `XCTOSSignpostMetric` performance tests with
baselines; Instruments App Launch, Animation Hitches and Hangs traces attached to
performance-related PRs; Main Thread Checker enabled in test schemes.

**Rationale**: A board game must respond instantly to touch, and measured budgets keep regressions
visible.

### VIII. Simplicity & Dependencies

1. Every third-party dependency MUST have a written justification in the plan covering why Apple
   frameworks fall short, its maintenance status (recent releases, open issues), and a license
   compatible with App Store distribution. Dependencies MUST be added through Swift Package
   Manager only, and `Package.resolved` MUST be committed.
2. Build-time tools named in this constitution (SwiftLint, swift-format) are pre-approved and need
   no further justification.
3. Work MUST be limited to what the current spec requires (YAGNI). Code, options or extension
   points for hypothetical future specs MUST NOT be added.

**Verified by**: the plan's Constitution Check lists every dependency with its justification;
review rejects scope not traceable to a spec requirement.

**Rationale**: Every dependency and speculative feature is a permanent maintenance cost.

### IX. Observability

1. Logging MUST use OSLog `Logger`, with the app bundle identifier as the subsystem and one
   category per feature. `print`, `debugPrint` and `NSLog` MUST NOT appear in shipped code.
2. Crashes and key errors MUST be reportable, using MetricKit diagnostics and Xcode Organizer
   before any third-party crash reporter (which falls under Principle VIII).
3. Logs MUST NOT contain PII. Dynamic values that could identify a user MUST use the default
   private redaction and MUST NOT be marked `privacy: .public`.

**Verified by**: a SwiftLint custom rule that bans `print(` outside test targets; review of every
`privacy: .public` interpolation.

**Rationale**: Structured, privacy-safe logs make field issues diagnosable without risking user
data.

## Platform & Technology Constraints

- **App**: A native checkers game for iPhone and iPad players.
- **Platform**: iPhone first; iPad supported, so layouts MUST adapt to iPad size classes. The
  minimum deployment target is iOS 26.2.
- **Toolchain**: The latest stable Xcode, Swift 6 language mode (`SWIFT_VERSION = 6`) and complete
  strict concurrency checking.
- **Distribution**: App Store, through TestFlight. Every App Store build MUST first be distributed
  through TestFlight.
- **Style**: SwiftLint and swift-format MUST run on every build and in CI. Code MUST follow the
  Swift API Design Guidelines.

## Development Workflow & Quality Gates

1. Every feature MUST follow spec → plan → tasks → implement. No implementation starts without an
   approved `tasks.md`.
2. Every plan MUST contain a "Constitution Check" section that evaluates each principle. Any
   violation MUST appear in the plan's Complexity Tracking table with the reason it is needed and
   the simpler alternative that was rejected. The check MUST be re-run after the design phase.
3. Commits MUST be small and reviewable. Each completed task MUST leave the app building and all
   tests passing.
4. Every SwiftUI view MUST have at least one `#Preview` that uses mock data. Previews MUST NOT
   touch the network or persistent storage.
5. A merge requires a green CI run: build, all tests, zero warnings, and zero SwiftLint errors.

## Governance

1. This constitution overrides all other practices, preferences and templates. When a plan, spec
   or task conflicts with it, the plan, spec or task MUST change. The constitution does not change
   to fit them.
2. An amendment MUST include a written rationale and a semantic version bump: MAJOR when a
   principle is removed or redefined in a backward-incompatible way, MINOR when a principle or
   section is added or guidance is materially expanded, and PATCH for clarifications and wording.
   Each amendment MUST include a sync check of the spec, plan and tasks templates, recorded in the
   Sync Impact Report.
3. Every code review MUST verify compliance with this constitution. Unjustified violations block
   the merge.
4. Dates use ISO format (YYYY-MM-DD). "Last Amended" MUST be updated with every amendment.

**Version**: 1.0.0 | **Ratified**: 2026-10-15 | **Last Amended**: 2026-10-15
