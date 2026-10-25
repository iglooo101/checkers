# Feature Specification: Release 1.0

**Feature Branch**: `008-release-1-0`

**Created**: 2026-10-24

**Status**: Draft

**Input**: User description: "E8 Release 1.0 (board epic #169, F8.0 #170, step #171): verify and
deliver the Checkers iPhone app as version 1.0 on the App Store. Scope: FRD.md v1.3 §18
(FR-PLAT-01, FR-PLAT-03, FR-PRIV-01, FR-PRIV-02), Constitution VI (privacy report from a signed
release archive), VII (cold launch under 400 ms, hitch-time ratio under 5 ms/s) and IX.2
(MetricKit diagnostics), and an FRD traceability check. Board tasks to trace: #177, #178, #179,
#192 (F8.1 Platform and privacy verification), #181, #182 (F8.2 Performance), #184 to #187 (F8.3
App Store delivery). Decisions agreed with the user before specifying: paid Apple Developer
Program membership; device checks on the user's iPhone; an original app icon drawn by a script;
privacy and support pages on GitHub Pages; store name chosen in App Store Connect; bundle ID kept;
free in all countries; uploads through an App Store Connect API key kept outside the repository;
TestFlight with the user and a few external testers; one release checklist that gathers every open
hand check and gates submission; manual release after approval. Branch 008-release-1-0 already
created by hand from main."

## User Scenarios & Testing *(mandatory)*

Two kinds of people are served. **Players** get the app the FRD describes, from the App Store,
and are owed what it promises: nothing leaves the phone, nothing asks for permission, and the game
opens and responds at once. **The owner** (the user, who publishes the app under their developer
account) needs evidence that every requirement holds on a real iPhone, a way to learn about crashes
and hangs after release, a store page, a beta round, and an approved submission. This slice adds no
game behavior: the app is feature complete after E6, and the FRD stays at version 1.3 unless the
beta round finds a behavior that must change.

The device for every on-device check is the owner's iPhone "HKH16" (an iPhone 16, model
iPhone17,3, on iOS 27.0.1), connected to the development Mac so that builds can be installed and
measured from there; the owner unlocks it and does the steps that need hands.

### User Story 1 - Every promise verified (Priority: P1)

The owner can show, requirement by requirement, that the app keeps the FRD's promises. On the
iPhone, a full session (both kinds of game, every screen) opens no network connection and shows no
permission prompt; the privacy report of a signed release build lists no collected data and no
tracking; the app stays in portrait whichever way the phone is turned; every user-facing text is
English and localizable; and a traceability matrix names, for every FRD requirement, the automated
test or the recorded manual check that covers it. (#176: #177, #178, #179; FR-PLAT-01, FR-PLAT-03,
FR-PRIV-01, FR-PRIV-02; Constitution VI)

**Why this priority**: The FRD's privacy and platform promises go on the store page as a privacy
label and a description; publishing them unverified would mislead players and risk rejection. The
traceability matrix is how the owner knows the app is complete.

**Independent Test**: Install a release build on the iPhone, play a session through every screen
while network activity is observed, turn the phone in every screen, read the signed build's privacy
report, and check that the traceability matrix lists every FRD v1.3 ID with a passing test or a
recorded check.

**Acceptance Scenarios**:

1. **Given** a fresh install of a release build on the iPhone, **When** the owner plays a game
   against the computer and a two-player game and opens every screen, **Then** no permission prompt
   appears and no network connection is opened by the app.
2. **Given** a signed release build, **When** its privacy report is generated, **Then** it lists no
   collected data types, no tracking and no tracking domains, and its declared reasons for
   required-reason interfaces match what the app uses.
3. **Given** any screen on the iPhone, **When** the phone is turned to either landscape orientation
   or upside down, **Then** the screen stays in portrait.
4. **Given** the smallest and the largest supported iPhone screens, **When** a game is shown,
   **Then** the whole board fits on screen in portrait.
5. **Given** the FRD v1.3, **When** the owner reads the traceability matrix, **Then** every
   requirement ID appears with at least one automated test or a recorded manual check, and the
   removed FR-PLAT-02 is marked as removed.

---

### User Story 2 - Fast and smooth on a real iPhone (Priority: P2)

A player taps the icon and the game is on screen at once; moving pieces, the computer's turns and
scrolling never stutter or freeze. The owner measures this with release builds on the iPhone:
the cold launch to the first frame, hitches and hangs during a scripted session, the computer's
timing (E4 SC-005) and the delay of each sound (E6 SC-004). (#180: #181, #182; Constitution VII)

**Why this priority**: A board game must respond instantly to touch (Constitution VII). The
simulator and the Mac have been the closest proxies so far; the targets are defined on an iPhone.

**Independent Test**: Install a release build on the iPhone, measure ten cold launches, then record
a scripted session (moves, drags, captures, crowning, undo, a game at each difficulty, scrolling
Rules and Statistics) and read its hitches, hangs, computer step timings and sound delays.

**Acceptance Scenarios**:

1. **Given** a release build on the iPhone and the app not running, **When** it is launched ten
   times from cold, **Then** the median time to the first frame is under 400 ms.
2. **Given** the scripted session, **When** its frames are recorded, **Then** the hitch-time ratio
   is under 5 ms per second and no hang of 250 ms or more occurs.
3. **Given** games against the computer at each difficulty on the iPhone, **When** each of its
   turns is timed, **Then** its first step appears 0.5 to 1 second after its turn starts in at
   least 95% of turns and never later than 1.5 seconds (E4 SC-005).
4. **Given** sound effects on, **When** a step appears, **Then** its sound is heard within 0.1
   second (E6 SC-004).
5. **Given** a measurement that misses its target, **When** the owner looks into it, **Then** a
   profile of the slow case is recorded before any optimization, and the measurement is repeated
   after the fix.

---

### User Story 3 - Crashes and hangs can be diagnosed after release (Priority: P2)

Once the app is in players' hands, the owner can learn why it crashed or hung. The app receives the
diagnostic reports the system collects on the phone (crashes, hangs, CPU and disk-write
exceptions, launch problems) and writes a short summary of each to the app's log, on the phone
only. Together with the crash reports Apple gathers from players who choose to share them, this
makes field problems diagnosable without the app collecting anything. (#176: #192; Constitution
IX.2, IX.3)

**Why this priority**: After release there is no other way to see what happens on players'
phones, and the constitution requires crashes and key errors to be reportable before any
third-party crash reporter is considered.

**Independent Test**: Deliver a simulated diagnostic report of each kind to a debug build and check
that each produces one log entry under the app's diagnostics category, with dynamic values
redacted by default, and that nothing is sent anywhere.

**Acceptance Scenarios**:

1. **Given** the app is running, **When** the system delivers a diagnostic report, **Then** the app
   logs one entry per diagnostic in it, naming its kind (crash, hang, CPU exception, disk-write
   exception or launch) and when it happened.
2. **Given** a diagnostic contains values that could identify the player, **When** it is logged,
   **Then** those values are redacted in the log by default.
3. **Given** a report that cannot be read, **When** it arrives, **Then** the failure is logged and
   the app goes on normally.
4. **Given** diagnostics are being received, **When** the privacy report is generated, **Then** it
   is unchanged: no collected data, no network use, no permission.

---

### User Story 4 - A recognizable app with a store page (Priority: P2)

A player finds the app on the App Store, sees an original icon, screenshots of the real game, a
plain description, the "Data Not Collected" label, an age rating of 4+ and a free price, and can
read a privacy policy and find support. On their Home Screen the app is called "Checkers", its icon
follows the light, dark and tinted Home Screen styles, and launching shows a plain screen that
gives way to Home without a flash. (#183: #184, #185)

**Why this priority**: The App Store requires an icon, screenshots, texts, a privacy label, a
privacy policy URL and a support URL before a build can be submitted, and the icon is required
before a build can even be uploaded to TestFlight.

**Independent Test**: Generate the icon with its script and check each variant at every size the
system uses; capture the screenshots with the automated run and check them against the required
size; open the privacy policy and support pages from their public addresses; review every store
field against the FRD.

**Acceptance Scenarios**:

1. **Given** the icon script, **When** it is run twice, **Then** it produces the same default, dark
   and tinted icons both times, and the owner approves them at Home Screen size and at store size.
2. **Given** the app installed on the iPhone, **When** the owner looks at the Home Screen in light,
   dark and tinted styles, **Then** the icon shows its matching variant and the name reads
   "Checkers".
3. **Given** the app launches in light or dark appearance, **When** the launch screen shows,
   **Then** it is a plain background with no text or logo, matching Home's background, so Home
   appears without a flash of another color.
4. **Given** the screenshot run, **When** it finishes, **Then** it has produced the store's required
   iPhone screenshots from set game states, showing only real app screens.
5. **Given** the public pages, **When** anyone opens the privacy policy or support address, **Then**
   the page loads and says, respectively, that the app collects no data, and how to get help.
6. **Given** the store listing in App Store Connect, **When** the owner reviews it before
   submission, **Then** every required field is filled, the privacy label is "Data Not Collected",
   and every statement about the app matches the FRD.

---

### User Story 5 - A beta round on TestFlight (Priority: P3)

Before any player gets the app, the owner and a few friends install it from TestFlight and use it
as players will. The owner runs one release checklist on the TestFlight build: E8's own device
checks plus every hand check left open by earlier slices (E3 to E7). Friends play it too, and one
who is new to checkers plays the E4 playtest against Easy. Problems found are fixed in new builds,
and the affected checks are run again. (#183: #186; Constitution: every App Store build first goes
through TestFlight)

**Why this priority**: It needs the verified app (US1 to US3) and the icon (US4), and it is the last
chance to find what automated tests cannot: VoiceOver by hand, sound on a real phone, whether a
beginner can beat Easy.

**Independent Test**: Upload a signed build, install it from TestFlight on the iPhone, invite the
external testers once Beta App Review has passed, and work through the release checklist until
every item is passed or accepted in writing.

**Acceptance Scenarios**:

1. **Given** a commit that passed CI, **When** the owner's upload runs, **Then** a signed build with
   version 1.0 and a build number higher than any earlier upload reaches TestFlight without asking
   any encryption export question.
2. **Given** the build is processed, **When** the owner installs it from TestFlight on the iPhone,
   **Then** it runs the same as the locally installed release build.
3. **Given** the build passed Beta App Review, **When** the external testers are invited, **Then**
   they can install it and see what to test.
4. **Given** the release checklist, **When** each item has been run on a TestFlight build, **Then**
   it records the result (passed, failed, or accepted by the owner in writing with the reason) and
   the build it was run on.
5. **Given** a problem found in the beta, **When** it is fixed, **Then** the fix goes through the
   usual tests and CI into a new TestFlight build, and every checklist item it could affect is run
   again on that build.

---

### User Story 6 - Submitted and approved (Priority: P3)

The owner submits the build that passed the release checklist for App Review, with notes that tell
the reviewer the app needs no account and works offline. Once Apple approves it, version 1.0 waits
for the owner to press Release. (#183: #187)

**Why this priority**: It is the last step and depends on everything else.

**Independent Test**: Submit the checked build and follow the review to approval, or through each
rejection to a resubmission, recording every round.

**Acceptance Scenarios**:

1. **Given** every release checklist item is passed or accepted in writing, **When** the owner
   submits version 1.0, **Then** it is the same build the checklist was completed on, and it is set
   to be released manually.
2. **Given** App Review approves it, **When** the owner checks App Store Connect, **Then** version
   1.0 is "Pending Developer Release", and E8 is complete.
3. **Given** App Review rejects it, **When** the owner reads the reason, **Then** the fix goes into
   the store listing or, through a new TestFlight build, into the app, and the version is
   resubmitted, with each round recorded.

---

### Edge Cases

- **The iPhone runs a newer iOS than the tests**: the phone is on iOS 27.0.1 while CI tests on iOS
  26.2, the minimum the app supports. The device checks therefore also check the current iOS; any
  difference found there is a beta finding. If the development tools cannot install, debug or
  measure on that iOS version, they are updated, together with CI's pinned version.
- **The iPhone is one generation older than "recent"**: it is an iPhone 16 (2024); see
  Assumptions for how its measurements count against Constitution VII.1.
- **Measurements are noisy**: the first launch after an install or a reboot is not a cold launch of
  the installed app and is not counted; all measured values are recorded, not only the median.
- **The phone is not connected or locked**: device steps wait for the owner; nothing is recorded
  as passed without a measurement or the owner's report.
- **The chosen store name is taken**: App Store Connect refuses it and the owner picks another; the
  Home Screen name stays "Checkers".
- **App Review runs the app on an iPad**: an iPhone-only app runs on iPad in the system's iPhone
  compatibility mode, and reviewers may use it there. It must work there in portrait as on an
  iPhone, although iPad is otherwise out of scope (FRD §19).
- **Macs and Apple Vision Pro**: an iPhone app is offered on Apple silicon Macs and on Apple Vision
  Pro unless the owner turns that off; it is turned off, since the app is neither designed nor
  tested for them.
- **Beta App Review delays or rejects the external round**: the owner's own round on the iPhone
  goes on; the external round waits for the fix or approval.
- **A tester's report needs a behavior change** (for example Easy proves too strong for a
  beginner): the FRD changes first, then the fix goes through spec, tests and CI, and the playtest
  is run again on the new build.
- **A new build replaces one in testing**: checklist results recorded on the old build stand only
  for items the change cannot affect; the others are run again.
- **The diagnostic reports arrive rarely**: the system delivers them at most about once a day and
  not on demand, so tests use simulated reports; a real report on the iPhone is welcome but not
  required.
- **The upload key leaks or is lost**: it is revoked in App Store Connect and replaced; it never
  enters the repository or a log, and a check before each push confirms no key material is
  committed.
- **A release-only problem**: anything that appears in the release build and not in the debug
  build used by the tests (for example optimization or signing differences) is found by the device
  checks, which run release builds only.

## Requirements *(mandatory)*

### Functional Requirements

**Privacy and platform (#176: #177, #178)**

- **FR-001**: The app MUST open no network connection at any time. An automated check MUST guard the
  app's code against networking, and a recorded observation of a full session on the iPhone MUST
  find no connection made by the app (FR-PRIV-01).
- **FR-002**: The app MUST request no system permission: the built app MUST declare no permission
  purpose, and a fresh install used through every screen on the iPhone MUST show no permission
  prompt (FR-PRIV-02).
- **FR-003**: The app MUST have no account, sign-in, analytics, advertising, tracking or
  third-party SDK, and all its data (saved game, record, settings) MUST stay on the device
  (FR-PRIV-01).
- **FR-004**: The privacy report of a signed release build MUST list no collected data types, no
  tracking and no tracking domains, and the reasons it declares for required-reason interfaces
  MUST match the app's use of them (Constitution VI; moved here from E1 SC-008).
- **FR-005**: The app MUST stay in portrait on every screen when the iPhone is turned, and the board
  MUST fit the smallest and the largest supported iPhone screens (FR-PLAT-01).
- **FR-006**: Every user-facing text MUST be English and localizable, with none left out of the
  app's localizable texts (FR-PLAT-03).

**Traceability (#176: #179)**

- **FR-007**: A traceability matrix MUST list every requirement ID of FRD v1.3, each with the
  automated tests that cover it or, where it cannot be automated, the recorded manual check and its
  result; FR-PLAT-02 is listed as removed. An ID with neither MUST get a test or a check in this
  slice.

**Diagnostics (#176: #192)**

- **FR-008**: The app MUST receive the diagnostic reports the system collects for it (crashes,
  hangs, CPU exceptions, disk-write exceptions and launch diagnostics) and log one entry per
  diagnostic, naming its kind and time, under a diagnostics category of the app's log
  (Constitution IX.1, IX.2).
- **FR-009**: Values in a logged diagnostic that could identify the player MUST be redacted by
  default (Constitution IX.3). Reports MUST stay on the device: the app MUST NOT send, store beyond
  the system log, or show them, and receiving them MUST NOT need a permission or change the privacy
  report.
- **FR-010**: Receiving a report MUST NOT interrupt or slow play; a report that cannot be read MUST
  be logged as a failure and otherwise ignored.

**Performance (#180: #181, #182)**

- **FR-011**: A release build MUST reach its first frame from a cold launch in under 400 ms on the
  iPhone, as the median of ten cold launches, with every value recorded (Constitution VII.1).
- **FR-012**: In a scripted session on the iPhone covering selecting, moving and dragging pieces,
  captures, chains, crowning, undo, a game against the computer at each difficulty, and scrolling
  Rules, Statistics, Settings and setup, the hitch-time ratio MUST stay under 5 ms per second, with
  no hang of 250 ms or more (Constitution VII.2, VII.3).
- **FR-013**: The computer's timing (E4 SC-005) and the sound delay (E6 SC-004) MUST be measured on
  the iPhone with a release build, closing those slices' open device checks.
- **FR-014**: A measurement that misses its target MUST be followed by a profile of the slow case
  before any optimization, and repeated after the fix (Constitution VII.4). The launch test that
  guards against regressions on CI MUST keep passing.

**App icon and launch screen (#183: #184)**

- **FR-015**: The app MUST have an original icon, a crowned checkers piece on board squares or a
  similar plain design, drawn by a script kept in the repository that produces the same images on
  every run. It MUST have the default, dark and tinted variants the Home Screen uses, be legible
  at the smallest size the system shows, use no transparency where the store forbids it, and be
  approved by the owner before the first upload.
- **FR-016**: The name under the icon MUST be "Checkers".
- **FR-017**: The launch screen MUST stay a plain background with no text or logo, matching Home's
  background in light and dark appearance.

**Store listing and public pages (#183: #185)**

- **FR-018**: The App Store listing MUST be complete before submission: a unique store name chosen
  by the owner, a subtitle, a description, keywords, a support URL, a privacy policy URL, the
  category Games › Board, the age rating from Apple's questionnaire (4+), a free price in every
  country and region, availability on iPhone only (Mac and Apple Vision Pro availability off),
  copyright, and notes for App Review. Its texts MUST be kept in the repository, be in English
  (U.S.), and describe only what the FRD specifies.
- **FR-019**: The listing's screenshots MUST be captured by an automated run on the iPhone screen
  size the store requires, from set game states, showing only real app screens with a clean status
  bar; running it again MUST give the same screenshots.
- **FR-020**: The privacy label MUST be "Data Not Collected", consistent with FR-004.
- **FR-021**: A privacy policy page and a support page MUST be public on GitHub Pages from this
  repository (iglooo101.github.io/checkers) before submission. The privacy policy MUST say that the
  app collects no data, uses no network, asks for no permission and keeps everything on the
  device; the support page MUST explain how to get help through GitHub Issues. No email address is
  published.
- **FR-022**: The app MUST declare that it uses no encryption beyond the exempt kinds, so uploads
  need no export compliance answers.

**Builds and the beta round (#183: #186)**

- **FR-023**: Every build sent to App Store Connect MUST be a signed release build of a commit that
  passed CI, with version 1.0 and a build number higher than every earlier upload, and the
  repository MUST record which commit each build number came from.
- **FR-024**: Uploads MUST use an App Store Connect API key kept outside the repository, readable
  only by the owner's account, never printed, logged or committed.
- **FR-025**: Every build submitted for review MUST first be distributed through TestFlight
  (Constitution, Distribution). The owner MUST test it internally on the iPhone, and a small group
  of external testers MUST be invited once Beta App Review has passed, with instructions on what to
  test and a feedback window of at least one week.
- **FR-026**: One release checklist MUST gather E8's device checks and every hand check left open
  by earlier slices: E3's hand-played game and its largest-text review; E7's VoiceOver game; E4's
  playtest (a beginner against Easy, an experienced casual player against Hard), Home while the
  computer thinks, and VoiceOver moves against the computer; E5's closing from the app switcher and
  Continue, Home while the computer thinks then Continue, finished games at Easy and Medium in
  Statistics, and VoiceOver reading Statistics; E6's sound delay, silent mode, volume buttons,
  other apps' music, a sound over another, and VoiceOver through Rules and Settings. Each item MUST
  record its result (passed, failed, or accepted by the owner in writing with the reason) and the
  build it was run on.
- **FR-027**: A problem found in the beta MUST be fixed through the usual flow (a behavior change in
  the FRD first; tests and CI for every code change) and shipped in a new TestFlight build, and every
  checklist item the fix could affect MUST be run again on that build.

**Submission (#183: #187)**

- **FR-028**: Version 1.0 MUST be submitted only when every release checklist item is passed or
  accepted in writing, and MUST be the build the checklist was completed on. It MUST be set to
  release manually: after approval it waits for the owner.
- **FR-029**: A rejection MUST be answered by fixing the listing, or the app through a new TestFlight
  build and FR-027, and resubmitting; each round's reason and answer MUST be recorded.
- **FR-030**: The commit of the approved build MUST be marked in the repository as version 1.0.

**Unchanged behavior**

- **FR-031**: The slice MUST NOT change game behavior, screens or texts, except to fix a problem
  found by its checks or the beta round (FR-027). All existing tests MUST keep passing.

### Traceability

| Board task | Requirements | FRD / Constitution |
|---|---|---|
| #177 No network, permissions, account or analytics; privacy report | FR-001 to FR-004 | FR-PRIV-01, FR-PRIV-02; VI |
| #178 iPhone portrait-only on devices | FR-005, FR-006 | FR-PLAT-01, FR-PLAT-03 |
| #179 FRD traceability check | FR-007 | every FRD v1.3 ID |
| #192 MetricKit diagnostics subscriber | FR-008 to FR-010 | IX.1 to IX.3 |
| #181 Cold launch under 400 ms | FR-011, FR-014 | VII.1, VII.4 |
| #182 Hitch-ratio check | FR-012, FR-013, FR-014 | VII.2 to VII.4 |
| #184 App icon and launch screen | FR-015 to FR-017 | Distribution |
| #185 Store metadata, screenshots, privacy label | FR-018 to FR-022 | FR-PRIV-01, FR-PRIV-02, FR-PLAT-03; VI |
| #186 TestFlight build and beta round | FR-023 to FR-027 | Distribution; every hand check of E3 to E7 |
| #187 Submit for App Store review | FR-028 to FR-030 | Distribution |

FR-031 applies to every task.

### Key Entities

- **Release build**: a signed release build sent to App Store Connect: version (1.0), build number,
  the commit it came from, and where it is (processing, TestFlight, submitted, approved).
- **Release checklist item**: one check to run on a TestFlight build: where it comes from (E8 or an
  earlier slice's validation log), what to do, its result (passed, failed, accepted in writing
  with a reason) and the build it was run on.
- **Traceability entry**: an FRD requirement ID with the tests that cover it or its recorded manual
  check.
- **Device measurement**: a metric measured on the iPhone (cold launch, hitch-time ratio, hangs, the
  computer's step timing, sound delay), with every value, the median where it applies, the build,
  the device and its iOS version.
- **Diagnostic report**: a report the system delivers to the app: its diagnostics (crash, hang, CPU
  exception, disk-write exception, launch), each with a kind and a time.
- **Store listing**: the store's texts, screenshots, category, age rating, price and availability,
  privacy label, and the privacy policy and support pages.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of FRD v1.3 requirement IDs (FR-PLAT-02 excepted, as removed) are mapped to at
  least one passing automated test or a recorded manual check with its result.
- **SC-002**: A full session on the iPhone, through every screen and both kinds of game, opens 0
  network connections and shows 0 permission prompts, and the signed build's privacy report lists 0
  collected data types and 0 tracking domains.
- **SC-003**: On the iPhone, a release build's median cold launch to the first frame, over ten
  launches, is under 400 ms.
- **SC-004**: Across the scripted session on the iPhone, the hitch-time ratio is under 5 ms per
  second and no hang lasts 250 ms or more.
- **SC-005**: The computer's first step appears 0.5–1 second after its turn starts in at least 95%
  of turns at every difficulty and never later than 1.5 seconds, and each sound is heard within
  0.1 second of its step, measured on the iPhone.
- **SC-006**: A simulated report of each of the five diagnostic kinds produces exactly one log entry
  each, with player-identifying values redacted, and no data leaves the phone.
- **SC-007**: The owner approves the icon's three variants at Home Screen and store sizes, and its
  script produces identical images on two runs.
- **SC-008**: App Store Connect shows no missing required item for version 1.0, and the privacy
  policy and support pages load from their public addresses.
- **SC-009**: Every release checklist item is passed, or accepted by the owner in writing, on the
  build that is submitted; at least one external tester new to checkers completes the Easy playtest
  (E4 SC-004: a beginner wins at least one of three games).
- **SC-010**: App Review approves version 1.0, which then waits in "Pending Developer Release".

## Assumptions

- **The iPhone's generation**: Constitution VII.1 sets the launch budget on "an iPhone from the last
  two hardware generations"; in October 2026 the owner's iPhone 16 (2024) is older than that. Its
  measurements count as passing evidence, since newer models are faster: a pass on it implies a
  pass on a recent iPhone. If a target is missed on it, the slow case is profiled and improved;
  only if it then still misses is a recent iPhone (for example an external tester's) used to
  decide. To confirm in `/speckit-clarify`.
- **iOS versions**: the app's minimum stays iOS 26.2 and CI keeps testing there; the device checks
  run on the phone's current iOS (27.0.1). Whether the development tools (Xcode 26.3, also pinned on
  CI) can install, debug and measure on iOS 27 is settled in the plan; if not, the development Mac
  and the CI pin are updated together. The plan also confirms the minimum SDK App Store Connect
  currently accepts.
- **Diagnostics and the privacy label**: the app reads the system's diagnostic reports on the phone
  and only logs them, so it collects no data and "Data Not Collected" stays true. Crash reports
  that players choose to share with developers are gathered by Apple, not by the app; the plan
  confirms this against Apple's privacy label guidance.
- **Key errors stay logged**: E5's restore failures and E6's sound and settings errors are already
  logged under their categories; this slice adds the system's diagnostic reports and no new
  reporting of its own.
- **The upload key** is a developer credential, not app data: Constitution VI.2 (secrets in the
  Keychain) governs what the app stores, and the app stores none. The key lives with the GitHub
  token outside the repository (FR-024).
- **Releases are built on the development Mac**: archiving, signing and uploading run from the
  owner's Mac with the API key; CI keeps building and testing every push and does not sign or
  upload.
- **The beta group**: the owner plus two to five friends, at least one new to checkers for the
  playtest; feedback comes through TestFlight's own feedback and screenshots, which Apple gathers
  for the owner, not the app.
- **The store page**: English (U.S.) only, no App Preview video, no in-app purchases, events or
  promotional offers; the primary category is Games with the Board subcategory. Screenshots use
  the app's default settings (Classic theme, hints on) in light appearance unless the owner prefers
  otherwise when approving them.
- **The launch screen**: the system-generated plain launch screen the app already has is kept; it
  is checked against Home's background in both appearances rather than redesigned.
- **The name under the icon**: the app's built name is currently its lowercase target name, so
  "Checkers" is set explicitly (FR-016); the bundle ID `Hussein-Helmy.checkers` stays.
- **Done at approval**: E8 ends when App Review approves version 1.0; pressing Release, and anything
  after it (updates, version 1.1), is the owner's and outside this slice.
- **No new product behavior**: FRD v1.3 and its out-of-scope list (§19) stand; iPad support, other
  languages and the other §19 items stay out.
