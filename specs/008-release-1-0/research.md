# Research: Release 1.0

Phase 0 output for `specs/008-release-1-0/plan.md`. Each entry records the decision, why, and what
else was considered. Facts marked *measured* were checked on 2026-10-25 on the development Mac
(MacBook Pro 15-inch 2019, Intel Core i9-9980HK, macOS 15.8.1, Xcode 26.3 17C529) and on the
owner's iPhone "HKH16" (iPhone 16, iPhone17,3, iOS 27.0.1 24A446), with throwaway probes that were
deleted afterwards. Facts marked *Apple* or *GitHub* come from their published documentation on
that date.

## Environment facts

| Item | Value |
|---|---|
| Toolchain | Xcode 26.3 with the iOS 26.2 SDK, the last Xcode this Mac runs: 26.4.1 to 26.6 need macOS Tahoe 26.2, Xcode 27 needs Tahoe 26.6 on Apple silicon, and Tahoe does not support this Mac (*Apple*: developer.apple.com/support/xcode, support.apple.com/122867). Constitution v1.2.0 makes this the toolchain |
| App settings | `MARKETING_VERSION = 1.0`, `CURRENT_PROJECT_VERSION = 1`, `PRODUCT_NAME = $(TARGET_NAME)` (so "checkers" under the icon), no `CFBundleDisplayName`, generated Info.plist, `UILaunchScreen_Generation = YES` (an empty launch screen), `TARGETED_DEVICE_FAMILY = 1`, portrait only, team 5RH237UKVE with automatic signing |
| App icon | `AppIcon.appiconset` has three empty 1024 px slots (any, dark, tinted); the app has no icon yet |
| Signing on this Mac | Apple Development and Apple Distribution certificates for the team; Xcode signed in; the development profile ("iOS Team Provisioning Profile: *") is valid until 2027-10-15 (*measured*) |
| Schemes and plans | One shared scheme, `checkers`: its build action builds `CheckersEngineTests` for testing, and its test action lists `checkers.xctestplan` (blocking; skips `LaunchPerformanceTests`) and `Performance.xctestplan` (`LaunchPerformanceTests` only, five iterations) |
| Logging | Categories `app`, `game`, `setup`, `computer`, `storage`, `settings`, `sound`. The computer logs its search time at debug level; nothing logs when the computer's first step appears or when a sound starts |
| Privacy checks today | `PrivacyManifestTests` (no tracking, no collected data, `UserDefaults` with CA92.1, no usage descriptions), `PlatformSettingsTests` (iPhone only, portrait), `NoWebContentTests`; the manifest declares nothing else |
| FRD coverage | FRD v1.3 has 85 requirement IDs; 84 are named in the test sources (app, UI and engine tests); the 85th is FR-PLAT-02, removed in 1.1 (*measured*) |
| CI | Runs on pushes to every branch but `main`; a push of `.md` files only skips build and tests (`scripts/ci/classify-changes.sh`). The workflow filters on branches only, so pushing a tag runs nothing (*GitHub*: a workflow with only branch filters does not run for tag pushes) |
| Repository | Public; GitHub Pages not enabled; no `docs/` folder (*measured*) |
| Simulators | iOS 26.3 runtime; iPhone 17 (CI's destination, 1206 × 2622 px screenshots); "iPad (A16) E8" created during this research |

## R1. What Xcode 26.3 can do on the phone's iOS 27.0.1

- **Decision**: Keep the phone as the measuring device, driven from this Mac. Everything the slice
  needs works on iOS 27.0.1 (*measured*): building, signing, installing and launching (2026-10-25,
  Debug and Release); attaching LLDB (`device select`, `device process attach`); running UI tests
  with `xcodebuild test`; XCTest's launch and hitch metrics (R4, R5); recording Instruments traces
  (`xctrace record`, App Launch template). Two limits: `xcodebuild test-without-building` with an
  `.xctestrun` file starts the test runner but cannot launch the app ("The process identifier of
  the launched application could not be determined", every time), so device runs use
  `xcodebuild test` with the scheme; and `xctrace export` crashes (segmentation fault) on every
  table of a trace recorded on iOS 27, while a simulator trace exports (3 MB), so traces from the
  phone are read in the Instruments app, not by scripts.
- **Rationale**: The fallback in the spec (TestFlight builds and the phone's own measurements) is
  not needed: the XCTest metrics and the app's log (R6) give every number as text. The first
  debugger attach took several minutes while Xcode copied the phone's iOS 27 symbols (6.6 GB, to
  `~/Library/Developer/Xcode/iOS DeviceSupport/iPhone17,3 27.0.1 (24A446)`); after that, attaching
  is immediate.
- **Found on the way**: Developer Mode was off on the phone partway through (`devicectl` reported
  "The operation failed because Developer Mode is disabled", and Instruments said "The device is
  missing the required developer tools"); after a reconnect the phone showed as unavailable for
  about 15 s. Every device script therefore starts by reading `xcrun devicectl device info
  details` (`tunnelState: connected`, `developerModeStatus: enabled`) and stops with a clear message
  otherwise.
- **Alternatives considered**: TestFlight builds with on-phone measurements only (rejected: slower,
  no launch or hitch numbers as text); a newer Mac with Xcode 27 (not available; the constitution
  keeps Xcode 26.3).

## R2. Which SDK App Store Connect accepts, and until when

- **Decision**: Build and upload 1.0 with Xcode 26.3 and the iOS 26.2 SDK, and submit it as soon as
  the checklist allows. Record the deadline as "until Apple requires the iOS 27 SDK", not as a
  date.
- **Rationale** (*Apple*, developer.apple.com/news/upcoming-requirements): "Since April 28, 2026:
  Apps uploaded to App Store Connect must be built with Xcode 26 or later using an SDK for iOS 26
  …". No iOS 27 SDK requirement has been announced as of 2026-10-25; Apple has raised the floor in
  the spring (the previous entries were April 2023, April 2024 and April 2026), so the spec's
  "until April 2027" is an expectation, not a published date. The spec's FR-032 and edge case say
  so now. The same page's deployment-target rule (iOS 13 or later since September 9, 2026) is met
  by iOS 26.2. The screenshot page notes that from April 2027 apps built with the iOS 27.1 SDK or
  later need screenshots for a new display size; 1.0 is built with the iOS 26 SDK and is not
  affected.
- **Alternatives considered**: none; the toolchain is fixed by FR-032 and the constitution.

## R3. Running Release builds and tests on the phone

- **Decision**: A second shared scheme, `checkers-device`, whose build action builds only the app
  and the UI tests, and whose test action uses a new `Device.xctestplan` holding the device-only
  UI tests (`LaunchPerformanceTests` and the session test of R5; `ScreenshotUITests` of R12 runs on
  the simulator through its own plan). Device runs use `xcodebuild test -scheme checkers-device
  -configuration Release -destination id=<udid>` with development signing; the scripts find the
  phone's identifiers by its name (`HKH16`, overridable) through `devicectl`, so no identifier is
  committed. The blocking plan skips the new UI test classes, as it skips
  `LaunchPerformanceTests`.
- **Rationale**: A Release test build of the `checkers` scheme fails on the engine's tests
  (`@testable import CheckersEngine`: "Unable to find module dependency"), and `-only-testing` does
  not narrow the build; a probe scheme without `CheckersEngineTests` in its build action built and
  ran (*measured*). The Release app is signed for development with `get-task-allow` (*measured*),
  which UI tests and the debugger need, and is otherwise the optimized build players get.
- **Alternatives considered**: Debug builds on the phone (rejected: the measured numbers would not
  be the shipped code's); `ENABLE_TESTABILITY` in Release (rejected: changes the code being
  measured); a user scheme (rejected: not in the repository, so not repeatable).

## R4. Cold launch to the first frame (FR-011, SC-003)

- **Decision**: Measure with the existing `LaunchPerformanceTests` (`XCTApplicationLaunchMetric`,
  which "measures the amount of time an application takes to display its first frame", per its
  header) in Release on the phone, run with `-test-iterations 2` for ten values; a script prints
  all ten and their median. The test itself does not change, so the simulator baseline on CI is
  unaffected.
- **Rationale**: *Measured*: five launches took 0.240, 0.237, 0.230, 0.230 and 0.231 s (median
  231 ms, against the 400 ms budget). XCTest terminates the app between iterations and leaves out
  its warm-up launch, which matches the spec's rule that the first launch after an install is not
  counted.
- **Alternatives considered**: Instruments' App Launch template (it records on the phone, but its
  tables cannot be exported, R1); MetricKit's launch histogram (arrives a day later, from players).

## R5. Hitches and hangs during play (FR-012, SC-004)

- **Decision**: One scripted UI session, `DeviceSessionUITests`, measured with `XCTHitchMetric`
  (new in the iOS 26 SDK) over the whole session (one iteration, started and stopped by hand
  around the session). It covers selecting, tapping and dragging moves, a capture chain, crowning,
  undo, a game against the computer at each difficulty, and scrolling Rules, Statistics, Settings
  and setup; set positions come from launch arguments, as in the UI tests. The pass rule:
  "Hitch Time Ratio" under 5 ms/s, and "Hitches Total Duration" under 0.25 s, which rules out any
  single hang of 250 ms or more. If either misses, the same session is recorded with Instruments
  (Animation Hitches and Hangs) and read in the Instruments app (Constitution VII.4).
- **Rationale**: *Measured*: `XCTHitchMetric(application:)` reports "Hitch Time Ratio" (ms per s),
  "Number of Hitches" and "Hitches Total Duration" on the phone; thirty fast Rules swipes in
  Release gave 0, 0 and 0 s in each of three iterations. XCTest reports no longest hitch, but a
  total under the hang threshold proves the bound; MetricKit's hang reports (R9) cover the field.
- **Alternatives considered**: Instruments alone (rejected: no text export from iOS 27 traces,
  R1); `XCTOSSignpostMetric.scrollingAndDecelerationMetric` (scrolling only).

## R6. The computer's timing and the sound delay on the phone (FR-013, SC-005)

- **Decision**: Two log lines at notice level with public numbers only: when the computer's first
  step of a turn appears, `GameSession` logs the time since its turn started (`computer`); when a
  sound starts, `SoundBank` logs the time since the step asked for it, and once per audio session
  the system's output latency (`sound`). The session of R5 runs against the app launched by
  `xcrun devicectl device process launch --console` with `OS_ACTIVITY_DT_MODE=YES`, which mirrors
  the app's log to the Mac; the UI test attaches to that running app with
  `XCUIApplication.activate()` instead of launching it. A script reads the captured log and checks
  SC-005: the computer's first step 0.5–1 s after its turn starts in at least 95% of turns and never
  later than 1.5 s, per difficulty; each sound's start plus the output latency within 0.1 s.
- **Rationale**: *Measured*: a Release build launched that way printed its own log lines with
  microsecond times on the Mac (`[settings] Stored setting moveHints is unreadable; using its
  default`, 0.24 s after launch), and a UI test using `activate()` drove that same process (the
  process ID was unchanged before and after) while the log kept streaming. UI test result bundles
  do not contain the app's log (*measured*), and trace tables cannot be exported (R1), so the log
  is the only text path. The lines are diagnostics in the sense of Constitution IX and change no
  behavior (FR-031).
- **Alternatives considered**: signposts read by Instruments (no export, R1); timing in the UI test
  (XCUITest polls about once a second, too coarse for a 0.5–1 s window); recording the screen with
  sound and reading frames (kept as the owner's ear check in the release checklist, not as the
  measurement).

## R7. No network connection and no permission (FR-001 to FR-003, SC-002)

- **Decision**: Three layers. A script test fails if the app's or the engine's sources use a
  networking or web API (`URLSession`, `URLRequest`, `NWConnection`, `import Network`, `WebKit`,
  `CFNetwork`, `Socket`) or an account, analytics or advertising framework. The existing tests keep
  the manifest and the absent usage descriptions (FR-002). On the phone, the owner turns on Settings
  › Privacy & Security › App Privacy Report before the release session and afterwards records that
  Checkers shows no network activity and no sensor or data access.
- **Rationale**: The App Privacy Report is the phone's own record of every app's network contacts,
  needs no tools, and works on any build, including TestFlight's. Instruments' Network template
  records on iOS 27 but cannot be exported (R1).
- **Alternatives considered**: packet capture through `rvictl` (needs root, and shows the whole
  phone's traffic); a proxy (needs a certificate on the phone and proves less).

## R8. The privacy report of the signed release build (FR-004)

- **Decision**: The owner generates Xcode's privacy report from the archive in the Organizer
  (Generate Privacy Report) for the build being submitted and records the result; a script check
  of the same archive confirms what the report summarizes: every `.xcprivacy` in the archived app
  declares no tracking, no tracking domains and no collected data, the only required-reason API is
  `UserDefaults` with CA92.1, and its Info.plist has no usage descriptions,
  `ITSAppUsesNonExemptEncryption` false and `CFBundleDisplayName` "Checkers".
- **Rationale**: `xcodebuild -help` lists no privacy report option (*measured*), so the report
  itself is a hand step; the script makes the same facts checkable on every archive, including
  those made between submissions.
- **Alternatives considered**: reading only the source manifest (rejected: the report is defined
  on the signed archive, Constitution VI).

## R9. Diagnostics after release (FR-008 to FR-010, SC-006)

- **Decision**: A `DiagnosticsSubscriber` (an `NSObject` conforming to `MXMetricManagerSubscriber`,
  the adapter the system API requires) registers with `MXMetricManager.shared` when the app starts.
  For each payload it takes `jsonRepresentation()` and hands the bytes to `DiagnosticReport`, a
  value type that reads the payload's `timeStampBegin` and `timeStampEnd` and one entry per item of
  `crashDiagnostics`, `hangDiagnostics`, `cpuExceptionDiagnostics`, `diskWriteExceptionDiagnostics`
  and `appLaunchDiagnostics`; a `DiagnosticsLog` writes one line per diagnostic under a new
  `diagnostics` category, naming the kind and the payload's time range as public values and any
  other detail with the default private redaction. Bytes that are not such a payload throw
  `DiagnosticError.unreadable`, which is logged once, and the app goes on (FR-010). Nothing is
  stored, shown or sent.
- **Rationale** (SDK headers): `MXDiagnosticPayload` offers the five arrays (launch diagnostics
  since iOS 16), the two time stamps and `JSONRepresentation`; the subscriber "is invoked on a
  background queue … at least once per day". Payload objects cannot be created in tests, but their
  JSON can, so the parser is tested with one fixture per kind, a payload with several diagnostics,
  and damaged bytes (SC-006). On the phone, Xcode's Debug › Simulate MetricKit Payloads (the
  debugger attaches on iOS 27, R1) delivers sample payloads to a running build, and their lines
  are read through the console of R6. MetricKit needs no permission and is not a required-reason
  API, so the privacy manifest does not change.
- **Alternatives considered**: reading the typed properties instead of JSON (rejected: no way to
  test the mapping or to meet "a report that cannot be read"); a third-party crash reporter
  (rejected: Constitution IX.2 and VIII, and it would collect data).

## R10. The app icon (FR-015, SC-007)

- **Decision**: `scripts/make-icon.py` (Python standard library only, like `make-sounds.py`) draws
  three 1024 × 1024 PNG files into `AppIcon.appiconset` and names them in its `Contents.json`:
  default (opaque, no alpha channel), dark (the same artwork on a transparent background) and
  tinted (grayscale). The artwork is one light king, a cream piece with its crown, centered on a
  two-by-two corner of Classic board squares (colors from the Classic theme: squares `#F1DFB9` and
  `#7A4A24`, piece `#FFFAF0` with edge `#A88F5F`, crown `#6B4426`), with no text and no thin lines,
  drawn as filled shapes with 4 × 4 supersampling for smooth edges. `--check` redraws in memory and
  compares with the committed files, allowing one step of difference per channel for another
  platform's floating-point rounding; it runs in the script tests on CI.
- **Rationale** (*Apple*, "Configuring your app icon using an asset catalog" and the HIG): iOS uses
  one 1024 px image per appearance ("Single Size") and generates the smaller sizes; "Provide your
  tinted app icon as a grayscale image"; "Provide your dark app icon with a transparent background
  so the system-provided background can show through"; the store's icon and screenshots must not
  have transparency; icons are square and the system rounds the corners; fine detail and thin lines
  disappear at small sizes. Keeping the Classic colors ties the icon to the default board. The
  owner approves the three variants at Home Screen and store sizes before the first upload, as with
  the sounds.
- **Alternatives considered**: an Icon Composer file (rejected: its layered format is made by the
  app, not documented for scripting, and nothing in FR-015 needs its glass effects); a drawing made
  by hand (rejected: FR-015 asks for a script).

## R11. The name under the icon, the launch screen and the encryption declaration

- **Decision**: Three build settings in the app target: `INFOPLIST_KEY_CFBundleDisplayName =
  Checkers` (FR-016), `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` (FR-022), and the
  existing generated launch screen kept as it is (FR-017). An `InfoPlist.xcstrings` catalog holds
  the display name, so the one user-facing text outside the app's screens is localizable too
  (Constitution V.4, FR-006). Unit tests read the built Info.plist: the display name, the
  encryption key, and a launch screen with no image or color (so the system background shows,
  the same as Home's).
- **Rationale**: Home has no background of its own (a scroll view on the system background), and
  the generated launch screen uses the system background in both appearances, so they already
  match; the owner confirms on the phone in light and dark (US4 scenario 3). The app uses no
  encryption beyond what iOS provides, so the declaration is the exempt answer.
- **Alternatives considered**: renaming the target or `PRODUCT_NAME` (rejected: changes the module
  name, bundle paths and every test import); a launch storyboard (rejected: spec keeps the
  generated screen).

## R12. The store screenshots (FR-019)

- **Decision**: `ScreenshotUITests`, run through its own `Screenshots.xctestplan` on the iPhone 17
  simulator by `scripts/screenshots.sh`, which first sets the simulator's status bar (9:41, full
  battery and signal, `xcrun simctl status_bar … override`), then exports the attachments and
  writes them as PNG files without alpha to `release/screenshots/` (1206 × 2622, light
  appearance, default settings). Six screens from set states: Home with Continue; a game against
  the computer with hints; a capture chain with its target marked; a crowned king; Rules; and
  Statistics with a record. Running it twice must give byte-identical files; the script compares
  them.
- **Rationale** (*Apple*, screenshot specifications): the one required iPhone set is "iPhone with
  Dynamic Island (medium display)", accepting 1179 × 2556 or 1206 × 2622 px; other iPhone sizes are
  scaled from it; up to 10 per size; `.png` or `.jpeg`; "Images can't include alpha channels or
  transparencies". The iPhone 17 simulator is CI's destination and produces 1206 × 2622.
  Launch arguments already set saved games and records (E5), so every screen is a real one.
- **Alternatives considered**: screenshots from the iPhone 16 (1179 × 2556; rejected: not
  repeatable without hands); framed or captioned images (rejected: FR-019 asks for real screens
  only).

## R13. The store listing, the public pages and availability (FR-018, FR-020, FR-021)

- **Decision**: The listing's texts live in `release/store-listing.md` (name proposal, subtitle,
  description, keywords, URLs, category, age rating answers, price, availability, copyright,
  review notes, privacy label answers); a script test checks Apple's limits on them: name 2–30
  characters, subtitle up to 30, description up to 4,000, keywords up to 100 bytes with each
  keyword over two characters, promotional text up to 170, review notes up to 4,000 bytes
  (*Apple*, App Store Connect Help). Each description paragraph names the FRD IDs it rests on in a
  comment, so the owner's review against the FRD (US4 scenario 6) is a lookup. The public pages are Markdown in `docs/` (`index.md` for support, `privacy.md`),
  published by GitHub Pages from `main` and `/docs` (enabled once through the API), at
  `https://iglooo101.github.io/checkers/` and `…/checkers/privacy/`. The owner enters the listing
  in App Store Connect and turns off availability on Apple silicon Macs and Apple Vision Pro there.
- **Rationale**: Markdown-only pushes skip CI (`classify-changes.sh`), so pages and texts cost no
  build; GitHub builds Pages itself with Jekyll's defaults, so no `_config.yml` (which would count
  as code) is needed. The repository is public, as free Pages requires. The privacy label stays
  "Data Not Collected" (*Apple*, App Privacy Details): "Data that is processed only on device is
  not 'collected' and does not need to be disclosed", and "You are not responsible for disclosing
  data collected by Apple", which covers the crash reports players share with developers.
- **Alternatives considered**: a `gh-pages` branch (rejected: a second history to keep); a GitHub
  Actions Pages workflow (rejected: a new workflow for two pages); texts only in App Store Connect
  (rejected: FR-018 keeps them in the repository).

## R14. Builds and uploads (FR-023, FR-024)

- **Decision**: `scripts/release.sh` archives the checked-out commit in Release for
  `generic/platform=iOS` with `CURRENT_PROJECT_VERSION` set to the next build number, checks the
  archive (R8), and uploads it with `xcodebuild -exportArchive` and `release/ExportOptions.plist`
  (`method` app-store-connect, `destination` upload, team 5RH237UKVE, automatic signing,
  `uploadSymbols` true, `manageAppVersionAndBuildNumber` false), passing
  `-allowProvisioningUpdates -authenticationKeyPath … -authenticationKeyID …
  -authenticationKeyIssuerID …` with the key from `../secrets`. Before archiving it refuses to run
  unless the working tree is clean, `CI gate` passed for `HEAD` (through `gh`), and the build
  number is higher than every recorded one. After the upload it appends the build number, commit,
  date and state to `release/builds.md` (FR-023). The approved build's commit gets the tag `v1.0`
  (FR-030). A script test fails if any tracked file contains private-key material or a `.p8` file,
  and `*.p8` is ignored by git (FR-024).
- **Rationale**: `xcodebuild -help` lists the authentication-key options and the export options
  `destination`, `method`, `manageAppVersionAndBuildNumber`, `testFlightInternalTestingOnly` and
  `uploadSymbols` (*measured*); App Store Connect accepts uploads from Xcode, altool, Transporter
  and its API (*Apple*). Passing the build number at archive time keeps `project.pbxproj` at 1, so
  an upload needs no code commit and no CI run. Whether the key's role also lets
  `-allowProvisioningUpdates` create the App Store profile is checked at the first upload; if it
  does not, the Xcode account already signed in on this Mac creates it and the key only uploads.
- **Alternatives considered**: altool with the key (kept as the fallback if the export upload
  fails); fastlane (rejected: Principle VIII); committing a build-number bump per upload (rejected:
  a CI run per upload for one number).

## R15. The traceability matrix (FR-007, SC-001)

- **Decision**: `scripts/traceability.py` reads every requirement ID from `FRD.md`, finds each in
  the test sources (`checkersTests`, `checkersUITests`, the engine's tests) and in the release
  checklist's manual items, and writes `specs/008-release-1-0/traceability.md`: one row per ID with
  its tests (file and test name) and its manual checks with their results; FR-PLAT-02 is listed as
  removed. `--check` fails if an ID has neither or if the file is out of date; it runs in the script
  tests on CI.
- **Rationale**: Test names already carry FRD IDs by convention, and 84 of the 85 IDs appear in the
  tests today (*measured*), so the matrix can be generated rather than kept by hand, and it cannot
  drift. IDs that are partly subjective (FR-AI-02's strength gaps) also list the playtest from the
  checklist.
- **Alternatives considered**: a hand-written matrix (rejected: 85 rows that drift with every
  test change).

## R16. The release checklist and the submission gate (FR-025 to FR-029)

- **Decision**: `specs/008-release-1-0/checklists/release.md` gathers every open hand check named in
  FR-026 (copied from E3 to E7's `validation.md` files, each with its source) and E8's own device
  checks, one table row each with columns for the build, the result (passed, failed, accepted) and,
  for accepted items, the reason in the owner's words. A check script (part of `scripts/release.sh
  submit-check`) confirms, for the build number about to be submitted, that every row is passed or
  accepted on that build or on an earlier build the change log marks as unaffected, and that the
  build is the latest uploaded one (FR-028). A rejection round is recorded in the same file
  (FR-029).
- **Rationale**: One file the owner edits on GitHub or in the repository, with a script that makes
  "every item passed or accepted" mechanical; FR-026's list is long enough that a gap is likely by
  hand.
- **Alternatives considered**: GitHub issues per item (rejected: 25 issues for one release); the
  board (rejected: the board tracks tasks, not test results).

## R17. The iPad compatibility smoke check (FR-005)

- **Decision**: Once per release build, the "iPad (A16) E8" simulator (iOS 26.3) runs the
  archive's app: launch, a few moves against the computer and in a two-player game, every screen,
  and rotation from the Simulator's Device menu; the result goes into the release checklist.
- **Rationale**: *Measured*: the iPhone-only app installs and launches on the iPad simulator in an
  iPhone-shaped window, which iPadOS 26 draws with window controls and a resize handle; Home
  shows normally. The check must also look at the window resized, since App Review may do that.
- **Alternatives considered**: automated iPad UI tests (rejected by the spec's clarification: no
  new automated tests, CI time unchanged).
