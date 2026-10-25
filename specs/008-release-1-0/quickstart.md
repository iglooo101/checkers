# Quickstart: Validating Release 1.0

How to check that this slice works, story by story. Commands run from the repository root.
Results go into `checklists/validation.md` (measurements, as in the data model's "Device
measurement") and `checklists/release.md` (the release checklist). Tooling details:
[release-tooling.md](contracts/release-tooling.md).

## Prerequisites

- The phone "HKH16" connected by cable and unlocked, Developer Mode on, Auto-Lock set to Never
  for the session (set it back afterwards). `scripts/device.sh status` must print
  `connected` and `enabled`.
- For uploads (§6): the App Store Connect key in `../secrets` (`AuthKey_<KEY_ID>.p8`, mode 600,
  and `appstoreconnect.txt` with `KEY_ID=` and `ISSUER_ID=`), and the app record in App Store
  Connect with the bundle ID `Hussein-Helmy.checkers`.
- The first debugger attach to a new iOS version copies its symbols (about 6.6 GB, several
  minutes); let it finish before measuring.

## 1. Automated checks (SC-001, SC-006, SC-007; every push)

```sh
scripts/tests/run.sh      # secrets, device status, network, traceability, archive check, timings, icon, listing, release guards
scripts/test.sh           # blocking plan: diagnostics parser and log, Info.plist values, all earlier tests
```

Expected: every script test passes (and `git push` runs the secrets check first, through the
pre-push hook); `traceability.py --check` reports every FRD ID covered and
FR-PLAT-02 removed; the diagnostics tests log exactly one entry per diagnostic and one failure
per damaged payload; `PlatformSettingsTests` reads "Checkers", the encryption key and the plain
launch screen.

## 2. Promises on the phone (US1, SC-002)

1. On the phone: Settings › Privacy & Security › App Privacy Report › on.
2. Install the Release build (`scripts/device.sh launch` installs it), delete any earlier copy
   first so the run is a fresh install. Play a game against the computer and a two-player game,
   open every screen (Home, setup, game, menu, Rules, Settings, Statistics), and turn the phone to
   both landscape sides and upside down on each. Expected: no permission prompt; every screen
   stays in portrait.
3. App Privacy Report › Checkers. Expected: no network activity, no data or sensor access.
4. Archive and check: `scripts/release.sh archive <build>` (runs `check`). Expected: the check
   passes. Open the archive (`open .build/Release/Checkers-1.0-<build>.xcarchive`, which adds it
   to Xcode's Organizer), then Generate Privacy Report for it. Expected: no collected
   data, no tracking, no tracking domains; `UserDefaults` with CA92.1 only.
5. iPad smoke check (FR-005): on the "iPad (A16) E8" simulator, install the same build's app,
   launch it, play a few moves against the computer and in a two-player game, open every screen,
   rotate (Device › Rotate) and resize the window. Expected: it works as on an iPhone, in
   portrait. Record in the release checklist.

## 3. Diagnostics on the phone (US3, SC-006)

Run the app from Xcode on the phone (Debug is fine), then Debug › Simulate MetricKit Payloads.
Expected in Xcode's console, under `[diagnostics]`: one line per simulated diagnostic with its
kind and time range, details shown as private when read without a debugger. Compare the
payload's key names with [diagnostics.md](contracts/diagnostics.md); a difference changes the
fixtures and the contract together.

## 4. Icon, name, launch screen, screenshots, listing, pages (US4, SC-007, SC-008)

```sh
python3 scripts/make-icon.py && python3 scripts/make-icon.py --check
scripts/screenshots.sh && scripts/screenshots.sh     # the second run reports no changed file
curl -sf https://iglooo101.github.io/checkers/ | grep -q "GitHub" && echo support ok
curl -sf https://iglooo101.github.io/checkers/privacy/ | grep -q "collects no data" && echo privacy ok
```

- **The owner approves** the three icon variants (open the PNG files, and on the phone the Home
  Screen in light, dark and tinted styles: Home Screen › Edit › Customize) and the six
  screenshots, or asks for changes.
- On the phone the name under the icon reads "Checkers".
- Launch in light and in dark appearance: the launch screen is plain and Home appears without a
  flash of another color.
- App Store Connect: every field of `release/store-listing.md` entered; availability on Apple
  silicon Macs and Apple Vision Pro off; the privacy label "Data Not Collected"; no missing item
  shown for version 1.0 (SC-008).

## 5. Performance on the phone (US2, SC-003 to SC-005)

```sh
scripts/device.sh launch     # ten cold launches, median under 0.4 s
scripts/device.sh session    # hitch ratio < 5 ms/s, total hitch time < 0.25 s; computer and sound timings
```

Expected: both pass; record every value with the build, device and iOS version. A miss: record
the same session in Instruments (Animation Hitches, Hangs, or App Launch) on the phone and read
it in the Instruments app before changing anything (Constitution VII.4); fix through tests and
CI; measure again. A miss that remains after that is measured on a newer iPhone (FR-014).
`TEST_PLAN=Performance scripts/test.sh` still passes on the simulator (the CI launch report).

## 6. TestFlight (US5, SC-009)

```sh
scripts/release.sh archive <build>      # clean tree, CI passed for HEAD, build number higher
scripts/release.sh upload .build/Release/Checkers-1.0-<build>.xcarchive
```

1. Expected: no export-compliance question; the build appears in App Store Connect › TestFlight
   and processes; `release/builds.md` gains its row.
2. Install it from TestFlight on the phone; it behaves as the local Release build.
3. Work through `checklists/release.md` on this build; record each result and the build.
4. Submit the build for Beta App Review; once approved, invite the external testers with what to
   test (one new to checkers plays E4's playtest: at least one win in three games against Easy)
   and a feedback window of at least a week.
5. A problem: FRD first if behavior changes, then tests and CI, a new build, and the affected
   items again (FR-027).

## 7. Submission (US6, SC-010)

```sh
scripts/release.sh submit-check <build>
```

Expected: it passes only when every checklist item is passed or accepted on that build. Submit
that build with the review notes, release set to manual. On approval: "Pending Developer
Release" in App Store Connect; `scripts/release.sh record <build> approved`; tag the commit
`v1.0` and push the tag. A rejection: record the reason and the answer, fix, resubmit (FR-029).

## 8. CI

Push the branch: `build-and-test` and `engine-strength` pass and `CI gate` is green. Markdown-only
pushes (pages, listing, checklists, records) skip the build.
