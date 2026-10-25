# Execution Plan

Last updated: 2026-10-24 · Board: [Checkers project](https://github.com/users/iglooo101/projects/1/views/1) · Source: `FRD.md` v1.3, constitution v1.1.0

This file tracks what is in progress and what is left to finish the project. It mirrors the
GitHub project board; when they disagree, fix both in the same change.

## How this file is maintained

- **Before starting any item, move it to In Progress on the board; once it is complete, move it
  to Done** (and close the issue): `scripts/project/board_move.py <status> <issue>...`. Update this
  file in the same step: `scripts/project/update_plan.py` regenerates the progress table, the
  in-progress list and the backlog (the parts between `GENERATED` markers); everything else here
  is written by hand.
- **Every close-out reviews and revises the whole file**: closing a task, feature or epic,
  finishing a Spec Kit slice, and ending a session (with `HANDOFF.md`).
- **Each epic is one Spec Kit slice.** Its `Fx.0 Specification` feature runs specify → clarify →
  plan → tasks/analyze, then the board tasks are reconciled with `tasks.md`. Implementation
  features are blocked by `Fx.0` on the board and are built with `/speckit-implement`.
- **Git**: solo repo. Work on a feature branch, fast-forward `main` locally and push; no pull
  requests unless needed. CI does not run for documentation-only changes.

### Close-out checklist

1. Board: item status matches reality; closed issues are Done; new work has issues.
2. Progress table and backlog checkboxes below match the board.
3. In progress and Next up are current.
4. Risks and open items: add new ones, remove resolved ones.
5. Add a dated line to the change log.

## Progress

Epics are listed in execution order.

<!-- BEGIN GENERATED: progress -->
| Order | Epic | Issue | Milestone | Priority | Features done | Tasks done | Status |
|---|---|---|---|---|---|---|---|
| 1 | E1 Project foundation | #1 | M1 Foundation | P0 | 6/6 | 22/22 | Done |
| 2 | E2 Rules engine | #29 | M2 Playable two-player game | P0 | 6/6 | 24/24 | Done |
| 3 | E3 Game experience | #57 | M2 Playable two-player game | P0 | 8/8 | 29/29 | Done |
| 4 | E7 Accessibility | #153 | M2 Playable two-player game | P0 | 5/5 | 11/11 | Done |
| 5 | E4 Computer opponent | #95 | M3 Computer opponent | P1 | 4/4 | 18/18 | Done |
| 6 | E5 Saving and statistics | #114 | M4 Feature complete | P1 | 3/3 | 18/18 | Done |
| 7 | E6 Settings, themes, sound and rules | #132 | M4 Feature complete | P1 | 5/5 | 17/17 | Done |
| 8 | E8 Release 1.0 | #169 | M5 Release 1.0 | P2 | 0/4 | 1/15 | In Progress |
| | **Total** | | | | **37/41** | **140/154** | |
<!-- END GENERATED: progress -->

## In progress

<!-- BEGIN GENERATED: in-progress -->
- #169 E8: Release 1.0
- #170 F8.0: Specification (Spec Kit)
- #172 E8 Clarify: resolve open questions with /speckit-clarify
<!-- END GENERATED: in-progress -->

## Next up

E1 Project foundation, E2 Rules engine, E3 Game experience, E7 Accessibility, E4 Computer
opponent, E5 Saving and statistics and E6 Settings, themes, sound and rules are done (slices
`specs/001-project-foundation/` to `specs/007-settings-themes-sound-and-rules/`, landed on
`main`, which is at `0109e93`). The app is fully native SwiftUI: Home,
setup, and a two-player game with tap and drag, hints, chains, crowning, undo, resign and a result
panel, playable square by square with VoiceOver (square states, announcements, focus that follows
each step), with non-color cues at 3:1 contrast and an accessibility audit of every screen. Games
against the computer are playable at three levels (E4): Medium scores 90 of 100 against Easy and
Hard 99 of 100 against Medium; the menu works while it thinks, Undo returns to the player's turn,
and VoiceOver announces its moves. Games are saved after every turn, on Home and in the
background, and Continue restores them; Start asks before abandoning a saved game; finished games
against the computer count in the record that Statistics shows; an unreadable save or record is
reported once (E5). With E6, Settings chooses one of three board themes (Classic, Modern,
Playful, with previews), turns the four original sounds and the move hints on and off, and Rules
explains the game in seven illustrated sections.

1. **E8 Release 1.0 (#169)**, the last epic, on branch `008-release-1-0`: spec written
   (`specs/008-release-1-0/spec.md`, #171 done); next `/speckit-clarify` (#172), which should
   confirm that the owner's iPhone 16 counts for Constitution VII.1's launch budget, then the
   plan (#173), which must settle whether Xcode 26.3 can install and measure on the phone's
   iOS 27.0.1.
2. Open for the user, from every epic (recorded in each slice's `checklists/validation.md`): E6's
   iPhone sound checks (a sound's delay, silent mode, the volume buttons, other apps' music, a
   sound over another) and VoiceOver through Rules and Settings; E4's playtest, iPhone timing and
   VoiceOver moves; E5's app-switcher and background checks; E7's VoiceOver game; E3's
   hand-played game and largest-text review.

## Order and dependencies

| Order | Epic | Depends on | Why this position |
|---|---|---|---|
| 1 | E1 Project foundation | Nothing | Test targets, CI, Swift 6 and lint come before any feature code. |
| 2 | E2 Rules engine | E1 | Pure engine package; everything else drives it. |
| 3 | E3 Game experience | E2 | Native board and two-player play on top of the engine. |
| 4 | E7 Accessibility | E3 | Moved before E4: VoiceOver and non-color cues shape the board view, and the constitution warns accessibility is costly to retrofit. |
| 5 | E4 Computer opponent | E3 | Computer turns run inside the game screen. #190 adds VoiceOver for its moves. |
| 6 | E5 Saving and statistics | E4 | Resume during the computer's turn and the record vs the computer need E4. |
| 7 | E6 Settings, themes, sound and rules | E3 | Settings, themes, sound and rules act on the game screen. |
| 8 | E8 Release 1.0 | All other epics | Verification and App Store delivery. |

E5 and E6 can swap places. Within an epic, the slice's `tasks.md` sets the final task order.

### Sequencing notes

- **E3 order**: board view → move input → move aids → undo → game end → app shell and menu →
  game setup. #67 (remove the HTML screens) comes last.
- **Saved game**: Continue on Home (#189) and "Abandon current game?" (#72) moved from E3 to
  E5, because both need the saved game.
- **E3 before E6**: E3 ships move hints on by default and the game menu's Rules and Settings
  entries without their screens; E6 adds the screens and the hints toggle.
- **E7 in later epics**: themes keep the non-color cues from #166 (#144), and each new screen's
  accessibility pass adds it to the audit test #168 (#131, #142, #152).

## Risks and open items

- Board tasks are a first cut from the FRD; each slice's `tasks.md` will add, split or close
  tasks during reconciliation.
- FR-AI-02 (noticeable strength gaps) is partly subjective. The matches (SC-003) pass by a wide
  margin (Medium 90, Hard 99 of 100); the playtest by the user (SC-004, E4 quickstart §4) is
  still open: a beginner must be able to beat Easy, which plays any turn within 40 points of its
  best two turns ahead.
- E5 makes app data outlive each UI test: saved games stay between tests and the record cannot be
  reset, so UI tests answer "Abandon current game?" in the start helpers and `tapStart()`, compare
  counts before and after, and set known states with `UserDefaults` launch arguments (research
  R10, confirmed in the simulator by T001).
- E6's settings outlive UI tests too: a test that changes a setting through the screen puts it
  back, and known values come from typed launch arguments (`-moveHints <false/>`; a plain `NO`
  reads as text; confirmed in the simulator by T007).
- E6's sound delay on an iPhone is unmeasured (SC-004: within 0.1 s); on the Mac each `play()`
  call takes 11–69 ms, so playback runs in an actor. If the iPhone check misses, move to
  `AVAudioEngine` (E6 research R7). Silent mode and other apps' music are checked by hand too.
- E6's sound tests prepare real `AVAudioPlayer`s in CI's simulator (the bundled files, and a bank
  over a directory with a file missing); this passes on CI's runners. The "Sound effects aren't
  available right now." notice cannot be caused in UI tests, so it is covered by unit tests and
  a preview, not the audit.
- E6's sounds and themes are approved (T021, T028). A later change to a sound must still pass
  its recipe check (`scripts/make-sounds.py --check`, which needs Python 3 on CI's runners) and
  the length tests; a changed color must pass `US4ContrastTests`.
- Timing checks on CI runners: the wall-clock SC-004 check failed once at 10.5 s on a runner
  about three times slower than usual (CI run 40023240169; a rerun passed). It now times the
  counting thread's CPU time (#202). Other wall-clock budgets (E4's Hard turn time, the launch
  test) can be hit the same way; E4's are measured alone, and the launch test only reports.
- E5's saved-game format is version 1; any change to `GameState`'s coding needs a new version, or
  older saves become unreadable (shown once on Home). A test fixture guards it.
- E4's checks by hand are open for the user: the playtest (§4), timing on an iPhone (§5; the
  Mac proxy is 419 ms), a VoiceOver game (§6), and pressing Home while the computer thinks (§3),
  which UI tests cannot do inside the half-second thinking.
- Launch time on a real iPhone is unmeasured until #181; the local baseline (Intel simulator,
  Debug build) is 3.6 s and only guards against regressions (the native app measured 2.1 s).
- E8's device is the owner's iPhone 16 (2024, iPhone17,3), older than Constitution VII.1's "last
  two hardware generations"; the spec counts a pass on it as evidence (newer models are faster),
  to be confirmed in clarify. The phone runs iOS 27.0.1 while development and CI use Xcode 26.3;
  if that Xcode cannot install or measure on iOS 27, both are updated together (E8 plan).
- Command-line builds do not update `Localizable.xcstrings`; run `scripts/sync-string-catalog.sh`
  after adding or removing strings, or CI fails. Plural variations (Statistics' counts) are
  written by hand in the catalog's layout; `scripts/check-string-catalog.sh
  checkers/checkers/Localizable.xcstrings .build/DerivedData` confirms a sync keeps them. Return
  optional strings from a `switch` with explicit `return`s, or the compiler extracts only one of
  them (HANDOFF.md, E3 lessons).
- E3 was validated by automated tests; a full game played by hand and a visual review at the
  largest text size are still open for the user (`specs/003-game-experience/checklists/validation.md`).
- E7's VoiceOver game by hand (SC-001, quickstart §3) is open for the user: XCUITest cannot drive
  VoiceOver, so announcements and focus are tested through the `Announcer` seam and the session.
- The accessibility audit allow-list has three entries, all Dynamic Type reports on system
  components: the setup row a scrolling form cuts at the screen's edge (a line, or Start with
  Computer chosen), the texts of system alerts (the abandon question, the restore notices), and
  since E6 the Settings texts its form cuts at the bottom edge (the Game section's header and
  footer); all scale on screen. Re-check them with each new iOS and Xcode
  (`specs/004-accessibility/plan.md`, `specs/006-saving-and-statistics/plan.md`,
  `specs/007-settings-themes-sound-and-rules/plan.md`).
- A CI runner can start without its simulators ready: US4's first run (40124926324, image
  `macos-26-arm64` 20261021) failed with "Unable to find a device" before building, and a rerun
  of the failed jobs on the same image passed. Rerun when the log shows that; if it happens on
  every run, the pinned destination (iPhone 17, iOS 26.2) or the Xcode pin must follow the image
  (`.github/workflows/ci.yml`).
- Audits at an arbitrary scroll position are not deterministic: text left under the navigation
  bar fails the contrast check wherever the swipe stops (E6 `validation.md` §6). Audit screens at
  their top or end.
- Code CI runs take 24–32 minutes by the end of E6 (`build-and-test` within its 45-minute limit
  since #204; the UI tests alone about 17 minutes), and a push cancels the running one; push once
  per story. If E8's tests bring it near 45 minutes, shorten the UI tests before raising it.
- CI pins Xcode 26.3 on GitHub's `macos-26` image; if the image drops it, CI fails until the pin
  and the development Mac are updated together.
- The engine's move generation is only moderately fast in Debug builds: the 6-turn reference
  count takes 5 s against SC-004's 10 s budget on the Intel Mac, and the whole engine suite
  about 24 s. E4's search uses its own allocation-free turn generator instead (built in US1:
  the search runs at 3.3–4.6 million nodes per second in Release); it must stay identical to the
  engine's rules, which the published counts and a 1,000-position cross-check enforce.
- E4's strength matches need Release builds, so they run in the `engine-strength` CI job beside
  `build-and-test`, and `CI gate` requires both (US2). The job takes 4.5 minutes on CI (budget
  15). Hard's slowest turn is 419 ms against a 0.5 s budget on this Mac, so a slower search would
  need a lower node limit.
- SC-005 (the computer's timing) is defined on a recent iPhone; without one, the Mac measurement
  is recorded as the closest proxy and the check stays open for the user.
- Debug builds search slowly (the simulator app and the blocking tests): Hard relies on the 0.8 s
  limit there, and engine tests in the blocking plan must use small search limits.
- The local `main` lags GitHub's (it moves by `git push origin <sha>:refs/heads/main`); run
  `git fetch origin main:main` before comparing branches. Merged slice branches (`001-…` to
  `006-…`) are deleted once the next slice's branch exists; the auto-mode safety check blocks
  deleting them, so the user runs it.

## Backlog

In execution order. Checkboxes mirror the board: `[ ]` Todo, `[~]` In Progress, `[x]` Done.
Sizes: S, M, L. "after #n" marks a blocked-by link between tasks.

<!-- BEGIN GENERATED: backlog -->
### E1 Project foundation (#1) · M1 Foundation · P0 · 22/22 tasks

**F1.0 Specification (Spec Kit)** (#2) · Constitution I–IX

- [x] #27 Confirm inferred constitution values (app description, iPad support, 400 ms launch budget) · S
- [x] #26 Amend tasks-template.md so tests are mandatory · S
- [x] #3 E1 Specify: write spec.md with /speckit-specify · S
- [x] #4 E1 Clarify: resolve open questions with /speckit-clarify · S
- [x] #5 E1 Plan: write plan.md with /speckit-plan, including the Constitution Check · M · after #27
- [x] #6 E1 Tasks: generate tasks.md with /speckit-tasks and check it with /speckit-analyze · S · after #26
- [x] #7 E1 Reconcile this epic's board tasks with tasks.md · S

**F1.1 Test and CI infrastructure** (#8) · Constitution III

- [x] #9 Add unit test target (Swift Testing) and UI test target (XCUITest) · M
- [x] #10 Add GitHub Actions CI: build and test on an iOS simulator · M · after #9
- [x] #11 Fail CI on compiler warnings and SwiftLint errors · S · after #10, #14, #16
- [x] #12 Protect `main`: require green CI before code lands · S · after #10, #11

**F1.2 Swift 6 and strict concurrency** (#13) · Constitution IV

- [x] #14 Switch to Swift 6 language mode with complete strict concurrency · S

**F1.3 Lint and format** (#15) · Constitution I, IV, IX

- [x] #16 Add SwiftLint with constitution rules · M
- [x] #17 Add swift-format configuration and run it in build and CI · S

**F1.4 Privacy, logging and localization baseline** (#18) · FR-PRIV-01, FR-PRIV-02, FR-PLAT-03

- [x] #19 Add PrivacyInfo.xcprivacy · S
- [x] #20 Add OSLog Logger with bundle-ID subsystem and per-feature categories · S
- [x] #21 Add String Catalog (Localizable.xcstrings) and treat its warnings as errors · S
- [x] #22 Configure iPhone only (device family 1), portrait only · S

**F1.5 Project structure and cleanup** (#23) · Constitution II

- [x] #24 Delete template leftovers (Item.swift, stray Assets.xcassets/CheckersApp.swift) · S
- [x] #25 Create local Swift package `CheckersEngine` with its own test target · M
- [x] #28 Add cold-launch performance test baseline (XCTApplicationLaunchMetric) · S · after #9
- [x] #191 Validate the E1 slice and update project docs · S

### E2 Rules engine (#29) · M2 Playable two-player game · P0 · 24/24 tasks

**F2.0 Specification (Spec Kit)** (#30) · FRD §8, §9, §10

- [x] #31 E2 Specify: write spec.md with /speckit-specify · S
- [x] #32 E2 Clarify: resolve open questions with /speckit-clarify · S
- [x] #33 E2 Plan: write plan.md with /speckit-plan, including the Constitution Check · M
- [x] #34 E2 Tasks: generate tasks.md with /speckit-tasks and check it with /speckit-analyze · S
- [x] #35 E2 Reconcile this epic's board tasks with tasks.md · S

**F2.1 Board model and starting position** (#36) · FR-RULE-01, FR-SETUP-06

- [x] #37 Board, square and piece types with a–h / 1–8 coordinates · S
- [x] #38 Standard starting position: 12 men per side, Light to move · S

**F2.2 Move generation** (#39) · FR-RULE-02, FR-RULE-03, FR-RULE-04, FR-RULE-05

- [x] #40 Man moves one square diagonally forward · S
- [x] #41 Man captures diagonally forward · S
- [x] #42 King moves and captures in all four directions (no flying kings) · M
- [x] #43 Mandatory capture: only captures are legal when one exists (any chain, not the longest) · S

**F2.3 Capture chains and crowning** (#44) · FR-RULE-06, FR-RULE-07, FR-CHAIN-01, FR-CHAIN-02, FR-CHAIN-03

- [x] #45 Apply a capture one jump at a time with chain-continuation state · M
- [x] #46 Crowning on the far row ends the turn, including mid-chain · S
- [x] #193 Reference move counts and speed check (SC-002, SC-004) · S · after #45, #46

**F2.4 Game state and endings** (#47) · FR-END-01, FR-END-02, FR-END-03, FR-END-04, FR-END-05

- [x] #48 Game state: board, side to move, pending chain, outcome · M
- [x] #49 Loss when the side to move has no legal move (or no pieces) · S
- [x] #50 Draw by threefold repetition (same position, same side to move) · M
- [x] #51 Draw by no progress: 40 moves per side without capture or man move · S
- [x] #52 Resignation outcome · S

**F2.5 Undo history** (#53) · FR-UNDO-01, FR-UNDO-02, FR-UNDO-05, FR-UNDO-06, FR-UNDO-07

- [x] #54 Turn history that restores full state, including draw counters · M
- [x] #55 Undo mid-chain restores the position from before the chain · S
- [x] #56 Undo is unavailable after the game has ended · S
- [x] #194 Random games: 1,000 seeded games end, stay legal and undo exactly (SC-003) · M · after #54
- [x] #195 Validate the E2 slice and update project docs · S · after #193, #194

### E3 Game experience (#57) · M2 Playable two-player game · P0 · 29/29 tasks

**F3.0 Specification (Spec Kit)** (#58) · FRD §4–7, §9, §10

- [x] #59 E3 Specify: write spec.md with /speckit-specify · S
- [x] #60 E3 Clarify: resolve open questions with /speckit-clarify · S
- [x] #61 E3 Plan: write plan.md with /speckit-plan, including the Constitution Check · M
- [x] #62 E3 Tasks: generate tasks.md with /speckit-tasks and check it with /speckit-analyze · S
- [x] #63 E3 Reconcile this epic's board tasks with tasks.md · S

**F3.3 Board view** (#74) · FR-GAME-01, FR-GAME-02, FR-GAME-03, FR-GAME-04, FR-GAME-05, FR-GAME-07, FR-SND-04

- [x] #75 SwiftUI board: 8×8 grid, men and kings, sized to fit every supported iPhone · M
- [x] #76 Board orientation: player's side at bottom vs computer; Light at bottom in two-player, no rotation · S
- [x] #77 Turn indicator, including "capture required" · S
- [x] #78 Accessibility pass: Game screen layout at accessibility5 and Dark Mode · S

**F3.4 Move input** (#79) · FR-MOVE-01, FR-MOVE-02, FR-MOVE-03, FR-MOVE-04, FR-MOVE-05

- [x] #80 Game model (@Observable): selection rules, tested without UI · M
- [x] #81 Tap a piece, then tap a target · S
- [x] #82 Drag a piece onto a target; invalid drops return the piece · M
- [x] #83 Tell the player a capture is required when they tap a piece that cannot capture · S

**F3.5 Move aids and chain interaction** (#84) · FR-AID-01, FR-AID-02, FR-AID-03, FR-AID-04, FR-CHAIN-02

- [x] #85 Highlight movable pieces and legal targets when hints are on · S
- [x] #86 Selected piece always visibly marked · S
- [x] #87 Chain lock: only the jumping piece and its next jumps are available · S

**F3.7 Undo in the game** (#93) · FR-UNDO-01, FR-UNDO-02, FR-UNDO-06

- [x] #94 Undo menu item with enable/disable rules; two-player undo takes back one turn · S

**F3.6 Game end and result** (#88) · FR-END-02, FR-END-06, FR-END-07, FR-END-08

- [x] #89 Resign with confirmation (human vs computer; side to move in two-player) · S
- [x] #90 Result panel over the final position with outcome and reason, Play again and Home · M
- [x] #91 Play again keeps opponent, difficulty and side; Random re-rolls the side · S
- [x] #92 Accessibility pass: result panel and confirmations · S

**F3.1 App shell and navigation** (#64) · FR-NAV-01, FR-NAV-02, FR-NAV-03, FR-NAV-04, FR-GAME-06

- [x] #65 Home screen with New game, Statistics, Rules and Settings · M
- [x] #66 Game screen menu: Undo, Resign, Rules, Settings, Home · M · after #75
- [x] #68 Accessibility pass: Home and navigation (Dynamic Type, Dark Mode, VoiceOver labels, previews) · S
- [x] #67 Remove the HTML screens, move.wav reference and WKWebView code · S · after #66, #81
- [x] #196 Validate the E3 slice and update project docs · S · after #67

**F3.2 Game setup** (#69) · FR-SETUP-01, FR-SETUP-02, FR-SETUP-03, FR-SETUP-05

- [x] #70 Setup screen: opponent, difficulty and side (Light, Dark, Random) · M
- [x] #71 Preselect last-used choices; first-use defaults Computer, Easy, Light · S
- [x] #73 Accessibility pass: Game setup · S

### E7 Accessibility (#153) · M2 Playable two-player game · P0 · 11/11 tasks

**F7.0 Specification (Spec Kit)** (#154) · FRD §17

- [x] #155 E7 Specify: write spec.md with /speckit-specify · S
- [x] #156 E7 Clarify: resolve open questions with /speckit-clarify · S
- [x] #157 E7 Plan: write plan.md with /speckit-plan, including the Constitution Check · M
- [x] #158 E7 Tasks: generate tasks.md with /speckit-tasks and check it with /speckit-analyze · S
- [x] #159 E7 Reconcile this epic's board tasks with tasks.md · S

**F7.1 VoiceOver board** (#160) · FR-A11Y-01, FR-A11Y-02

- [x] #161 Each square is a VoiceOver element: coordinate, contents, state ("c3, Light man, can move") · M
- [x] #162 Double-tap to select and to move, including chains; UI test · M

**F7.2 VoiceOver announcements** (#163) · FR-A11Y-03

- [x] #164 Announce moves (both sides), captures, crowning, turn changes, mandatory captures and results · M

**F7.3 Non-color cues** (#165) · FR-A11Y-05

- [x] #166 Kings, selection and hints distinguishable without color in every theme · S

**F7.4 Accessibility audit automation** (#167) · FR-A11Y-04

- [x] #168 UI test running performAccessibilityAudit() on every screen · M
- [x] #197 Validate the E7 slice and update project docs · S · after #168

### E4 Computer opponent (#95) · M3 Computer opponent · P1 · 18/18 tasks

**F4.0 Specification (Spec Kit)** (#96) · FRD §11

- [x] #97 E4 Specify: write spec.md with /speckit-specify · S
- [x] #98 E4 Clarify: resolve open questions with /speckit-clarify · S
- [x] #99 E4 Plan: write plan.md with /speckit-plan, including the Constitution Check · M
- [x] #100 E4 Tasks: generate tasks.md with /speckit-tasks and check it with /speckit-analyze · S
- [x] #101 E4 Reconcile this epic's board tasks with tasks.md · S

**F4.1 AI search** (#102) · FR-AI-01, FR-AI-02

- [x] #103 Position evaluation function · M
- [x] #104 Cancellable alpha-beta search off the main actor · L
- [x] #105 Difficulty levels Easy, Medium, Hard with measurable strength gaps · M
- [x] #199 Run the strength matches in a Release CI job that the CI gate requires · S

**F4.2 Computer turn** (#106) · FR-AI-03, FR-AI-04, FR-AI-05, FR-AI-06, FR-MOVE-04

- [x] #107 Computer turn controller: thinking indicator, 0.5–1 s pause, board input locked · M
- [x] #108 Show the computer's capture chains one jump at a time · S
- [x] #190 Announce the computer's moves with VoiceOver · S · after #164
- [x] #109 Computer makes the first move when it plays Light · S
- [x] #110 UI stays responsive while thinking: menu, Undo and Home work · S
- [x] #198 Start computer games from Game setup: first-use defaults, choices remembered on start · S

**F4.3 Undo against the computer** (#111) · FR-UNDO-03, FR-UNDO-04

- [x] #112 Undo takes back the player's turn and the computer's reply; unavailable before the first move · S
- [x] #113 Undo while the computer thinks cancels its turn · S
- [x] #200 Validate the E4 slice and update project docs · S · after #113

### E5 Saving and statistics (#114) · M4 Feature complete · P1 · 18/18 tasks

**F5.0 Specification (Spec Kit)** (#115) · FRD §12, §13

- [x] #116 E5 Specify: write spec.md with /speckit-specify · S
- [x] #117 E5 Clarify: resolve open questions with /speckit-clarify · S
- [x] #118 E5 Plan: write plan.md with /speckit-plan, including the Constitution Check · M
- [x] #119 E5 Tasks: generate tasks.md with /speckit-tasks and check it with /speckit-analyze · S
- [x] #120 E5 Reconcile this epic's board tasks with tasks.md · S

**F5.1 Auto-save and resume** (#121) · FR-SAVE-01, FR-SAVE-02, FR-SAVE-03, FR-SAVE-04, FR-SAVE-05, FR-END-08, FR-NAV-02, FR-NAV-03, FR-SETUP-04

- [x] #122 Codable game snapshot: position, side, opponent, difficulty, undo history, counters · M
- [x] #123 Saved-game store behind a protocol (live and in-memory fake) · M
- [x] #124 Save after every turn and when the app goes to the background · S
- [x] #125 Continue restores the game exactly; computer resumes if it was its turn · M
- [x] #126 Unreadable save: discard, hide Continue, tell the player · S
- [x] #127 Clear the saved game on game end and on abandon · S
- [x] #189 Show Continue on Home only when a saved game exists · S · after #65, #123
- [x] #72 "Abandon current game?" confirmation when a saved game exists · S · after #123

**F5.2 Statistics** (#128) · FR-STAT-01, FR-STAT-02, FR-STAT-03, FR-STAT-04, FR-STAT-05, FR-STAT-06, FR-SETUP-05, FR-UNDO-08

- [x] #129 Record model and recording rules (wins/losses/draws per difficulty) · M
- [x] #130 Statistics screen with empty state · M
- [x] #202 Time the 6-turn reference count by its thread's CPU time, not the wall clock · S
- [x] #131 Accessibility pass: Statistics · S
- [x] #201 Validate the E5 slice and update project docs · S · after #131, #202

### E6 Settings, themes, sound and rules (#132) · M4 Feature complete · P1 · 17/17 tasks

**F6.0 Specification (Spec Kit)** (#133) · FRD §14, §15, §16

- [x] #134 E6 Specify: write spec.md with /speckit-specify · S
- [x] #135 E6 Clarify: resolve open questions with /speckit-clarify · S
- [x] #136 E6 Plan: write plan.md with /speckit-plan, including the Constitution Check · M
- [x] #137 E6 Tasks: generate tasks.md with /speckit-tasks and check it with /speckit-analyze · S
- [x] #138 E6 Reconcile this epic's board tasks with tasks.md · S

**F6.1 Settings** (#139) · FR-SET-01, FR-SET-03, FR-SET-04, FR-AID-01, FR-AID-02, FR-AID-03, FR-AID-04, FR-NAV-04, FR-A11Y-04, FR-PLAT-03

- [x] #140 Settings store with defaults (Classic, sound on, hints on), persisted behind a protocol · S
- [x] #141 Settings screen; changes apply immediately, including in a game in progress · M
- [x] #142 Accessibility pass: Settings · S

**F6.2 Board themes** (#143) · FR-SET-02, FR-GAME-07, FR-A11Y-05

- [x] #144 Classic, Modern and Playful themes as asset-catalog colors with dark variants · M
- [x] #145 Theme picker with board previews · S

**F6.3 Sound effects** (#146) · FR-SND-01, FR-SND-02, FR-SND-03, FR-SND-04, FR-SND-05, FR-PRIV-02

- [x] #147 Sound assets: move, capture, crowning, game end · S
- [x] #148 Sound service behind a protocol that respects silent mode and volume · M

**F6.4 Rules screen** (#149) · FR-HELP-01, FR-HELP-02, FR-NAV-04, FR-A11Y-04, FR-PLAT-03

- [x] #150 Illustrated rules content: setup, moving, captures, chains, crowning, win/draw, undo/resign · M
- [x] #151 Rules reachable from Home and the game menu · S
- [x] #152 Accessibility pass: Rules · S
- [x] #203 Validate the E6 slice and update project docs · S · after #142, #152
- [x] #204 Give CI's build-and-test job a 45-minute time limit · S

### E8 Release 1.0 (#169) · M5 Release 1.0 · P2 · 1/15 tasks

**F8.0 Specification (Spec Kit)** (#170) · FRD §18

- [x] #171 E8 Specify: write spec.md with /speckit-specify · S
- [~] #172 E8 Clarify: resolve open questions with /speckit-clarify · S
- [ ] #173 E8 Plan: write plan.md with /speckit-plan, including the Constitution Check · M
- [ ] #174 E8 Tasks: generate tasks.md with /speckit-tasks and check it with /speckit-analyze · S
- [ ] #175 E8 Reconcile this epic's board tasks with tasks.md · S

**F8.1 Platform and privacy verification** (#176) · FR-PLAT-01, FR-PLAT-03, FR-PRIV-01, FR-PRIV-02

- [ ] #177 Verify no network requests, no permission prompts, no account or analytics · S
- [ ] #178 Verify iPhone portrait-only on devices · S
- [ ] #179 FRD traceability check: every FR ID covered by a test or a manual check · S
- [ ] #192 Add a MetricKit diagnostics subscriber for crashes and hangs · S

**F8.2 Performance** (#180) · Constitution VII

- [ ] #181 Cold launch under 400 ms on a recent iPhone (release build) · S
- [ ] #182 Hitch-ratio check during play and AI turns · S

**F8.3 App Store delivery** (#183)

- [ ] #184 App icon and launch screen · M
- [ ] #185 App Store metadata, screenshots and privacy label (Data Not Collected) · M
- [ ] #186 TestFlight build and beta round · S
- [ ] #187 Submit for App Store review · S
<!-- END GENERATED: backlog -->

## Change log

- 2026-10-16: Backlog created from `FRD.md` v1.0: 8 epics, 41 features, 138 tasks (#1–#187),
  nested as sub-issues and added to the board with Level, Epic, Priority and Size fields.
- 2026-10-16: #10 and #12 revised: no CI for documentation-only changes, and no pull requests
  (fast-forward merges keep CI results valid on `main`). Constitution-based issues now point to
  the constitution instead of the FRD.
- 2026-10-16: `docs/frd` fast-forwarded into `main` (PR #188 merged).
- 2026-10-16: Sequencing review. #26 and #27 moved into F1.0 ahead of #3; #72 moved and #189
  added to E5 (both need the saved game); #190 added to E4 for VoiceOver of the computer's
  moves; E3 features reordered; E7 moved before E4 (milestone M2, priority P0); 62 blocked-by
  links added on the board, including every implementation feature on its Fx.0. Backlog
  is now 8 epics, 41 features, 142 tasks.
- 2026-10-16: #27 done. Constitution 1.1.0 and `FRD.md` 1.1: iPhone only, portrait; the app
  description matches the FRD; the 400 ms launch budget is confirmed. #22, #75 and #178 were
  retitled and FR-PLAT-02 removed from #74–#78 and #176–#179.
- 2026-10-16: #26 done. Tests are mandatory and test-first through the Spec Kit override
  `.specify/templates/overrides/tasks-template.md`; the core template is unchanged. #6 is
  unblocked.
- 2026-10-16: #3 done. `specs/001-project-foundation/spec.md`: 6 user stories, 21 functional
  requirements traced to #9–#28, 9 success criteria; quality checklist passed.
- 2026-10-16: #4 done. Five clarifications: no owner bypass on `main`; launch test reports
  in CI but never fails it; local builds only warn on formatting; docs-only means `.md` files
  only; only lint errors fail CI.
- 2026-10-16: #5 done. `plan.md` with research R1–R15, data model, quickstart and contracts
  (CI gate, lint rules). SwiftLint via its official package plugin, swift-format from Xcode.
  Spec aligned with the constitution: privacy manifest lists only APIs in use; lint also bans
  `@Published`, `OperationQueue`, `Thread`. Notes added to #19, #71, #140.
- 2026-10-16: #6 done. `tasks.md`: 61 tasks, test-first. `/speckit-analyze` found 12 issues
  (2 critical); all fixed, including CI no longer running on `main` and launch-test errors
  blocking CI. Archive privacy report moved to #177.
- 2026-10-16: #7 done: board reconciled with `tasks.md`; #191 (slice validation and docs) and
  #192 (MetricKit, E8) added. F1.0 (#2) closed. Implementation started.
- 2026-10-16: #9 done (US1): test targets, shared scheme, test plan, `scripts/test.sh`; US1
  acceptance tests pass, including a real move on the Play screen.
- 2026-10-16: US2–US6 implemented on `001-project-foundation`. CI workflow with the `CI gate`
  check; Swift 6; SwiftLint and swift-format; CheckersEngine; privacy manifest, logger, string
  catalog, iPhone-only portrait; leftovers removed; launch baselines. CI probes confirmed
  failing tests, warnings, lint errors and formatting turn the gate red. #11, #14, #16, #17,
  #25 and features F1.2, F1.3 done. GitHub access now uses the token in `../secrets/`.
- 2026-10-16: E1 done. All 61 slice tasks complete and validated (`checklists/validation.md`);
  `main` is protected by the `CI gate` check (an unchecked push was rejected, a checked
  fast-forward accepted). Closed #10, #12, #18–#24, #28, #191, features F1.1–F1.5 and E1.
- 2026-10-16: E2 started. #31 done: `specs/002-rules-engine/spec.md`, 5 stories, 26 functional
  requirements traced to #37–#56, checklist 16/16.
- 2026-10-16: #32 done. Three clarifications: a win beats a draw on the same turn; every step
  returns a step result (new FR-027); repetition counts turn starts and undo uncounts.
- 2026-10-16: Session close-out. E1 done; E2 specified and clarified (#31, #32); next is #33
  Plan. HANDOFF.md updated with working rules, current state, lessons and next steps.
- 2026-10-16: Merged branch `001-project-foundation` deleted. Board and plan helpers committed
  under `scripts/project/` (`board_move.py`, `update_plan.py`); this file's progress table,
  in-progress list and backlog are now generated between `GENERATED` markers, the rest is
  hand-written. Session closed out; next is #33 Plan.
- 2026-10-21: #33 done. `specs/002-rules-engine/plan.md` with research R1–R12, data model, engine
  API contract and quickstart; Constitution Check passes before and after design. Reference
  counts for SC-002 come from OEIS A133046 and Aart Bik's checkers page (depths 1–7 in the
  blocking suite) and were reproduced independently to depth 9. SC-003 reworded: undo starts
  before each game's final turn (FR-024). Next is #34 Tasks.
- 2026-10-21: #34 done. `specs/002-rules-engine/tasks.md`: 37 tasks, test-first, by story.
  `/speckit-analyze` found 8 issues (1 critical: the reference-count and random-game tests came
  after the code they check); all fixed, so the reference counts are written with US3 (depth 7
  fails until chains and crowning exist) and the random games with US5. FR-020 now lists
  "nothing to undo".
- 2026-10-21: #35 done: board reconciled with `tasks.md`; #37–#56 list their task IDs; added
  #193 (reference counts, F2.3), #194 (random games, F2.5) and #195 (slice validation and docs,
  F2.5). F2.0 (#30) closed. Backlog is now 8 epics, 41 features, 145 tasks. Next is
  implementation, starting with T001.
- 2026-10-21: E2 implemented test-first in `checkers/CheckersEngine` (T001–T037): value types,
  simple moves (US1), captures and kings (US2), chains and crowning with the published reference
  counts for depths 1–7 (US3), endings (US4), and undo with 1,000 seeded random games (US5).
  63 engine tests, all 21 FRD IDs named; the Xcode test plan passes 72/72 and CI is green
  (run 39680886427). Found: `swift test` does not run SwiftLint (the Xcode build does);
  `identifier_name` now accepts `to`.
- 2026-10-21: E2 done. Closed #37, #38, #40–#43, #45, #46, #48–#52, #54–#56, #193–#195, features
  F2.1–F2.5 and epic #29; `main` fast-forwarded. Next is E3 (#59 Specify).
- 2026-10-21: E3 started on branch `003-game-experience`. #59 done:
  `specs/003-game-experience/spec.md`, 7 stories, 41 functional requirements traced to #65–#94,
  checklist 16/16; four assumptions go to #60 Clarify.
- 2026-10-21: #60 done. Three clarifications: a computer game cannot start until E4 (Computer is
  still choosable and remembered; first-use opponent Two players until then); leaving an
  unfinished game asks for confirmation and discards it until E5 (new FR-042); Statistics, Rules
  and Settings are placeholder screens until E5/E6.
- 2026-10-21: #61 done. `specs/003-game-experience/plan.md` with research R1–R14, data model,
  contracts (`game-session.md`, `screens.md`) and quickstart; Constitution Check passes and
  resolves E1's web-content exception. Next is #62 Tasks + analyze.
- 2026-10-21: #62 done. `specs/003-game-experience/tasks.md`: 60 tasks, test-first, by story.
  `/speckit-analyze` found 6 issues (1 high: previews can use only the engine's public API, so
  T002 makes `Position.init(_:)` and `GameState.init(position:sideToMove:)` public); fixed with
  FR-009's wording and a selected-state UI check; three low findings accepted.
- 2026-10-21: #63 done: board reconciled; #65–#94 list their task IDs; added #196 (slice
  validation and docs, F3.1). F3.0 (#58) closed. Backlog is now 146 tasks. Next is
  implementation, starting with T001.
- 2026-10-21: E3 implemented test-first (T001–T060): catalog sync script and public engine
  initializers (setup), then US1 Home, setup and tapped moves; US2 captures, chain lock and
  crowning; US3 hints and drag and drop; US4 resign, result panel and Play again; US5 undo; US6
  setup choices remembered in UserDefaults (privacy manifest CA92.1); US7 the full game menu,
  leave confirmation, placeholders and removal of the web prototype. 130 tests pass locally and
  in CI (run 39708152757); launch 2.1 s against the 3.6 s baseline. Found: optional `switch`
  expressions lose strings in extraction; confirmation dialogs from toolbars lack Cancel on
  iOS 26 (alerts used).
- 2026-10-21: E3 done. Closed #65–#94, #196, features F3.1–F3.7 and epic #57; `main`
  fast-forwarded. Next is E7 (#155 Specify).
- 2026-10-22: E7 started on branch `004-accessibility`. #155 done: `specs/004-accessibility/spec.md`,
  5 stories, 19 functional requirements traced to #161–#168, checklist 16/16; three assumptions go
  to #156 Clarify.
- 2026-10-22: #156 done. Three clarifications: VoiceOver square states are always given; Light and
  Dark differ by lightness (at least 3:1), no extra mark; one announcement per step, including the
  turn that follows.
- 2026-10-22: #157 done. `specs/004-accessibility/plan.md` with research R1–R8, data model,
  contract `announcements.md` and quickstart; Constitution Check passes. Measured the Classic
  palette: dark pieces, the selection ring, target dots and the crown on Light kings were below
  3:1 against their background; the plan changes those colors and adds FR-020. Next is #158 Tasks.
- 2026-10-22: #158 done: `specs/004-accessibility/tasks.md`, 26 tasks; `/speckit-analyze` found 4
  issues, none critical or high (a reading-order test added). #159 done: board reconciled, #197
  added. F7.0 (#154) closed. Backlog is now 147 tasks. Next is implementation.
- 2026-10-22: E7 implemented on `004-accessibility` (26 tasks). US1 square states (#161), US2
  VoiceOver play and focus (#162), US3 one announcement per step, undo and resignation (#164),
  US4 3:1 contrast for every mark with side-specific crowns (#166) and US5 an accessibility audit
  of all 10 screen states (#168). The audit's first run found 20 problems; fixed with an app
  `AccentColor` and `OnAccent`, primary text, an opaque result panel and the computer note under
  the opponent choice; two system-component issues on the Computer setup are allow-listed. 163
  tests pass, also audited on the iPhone SE at the largest text in Dark Mode. CI failed once on
  a system banner over the app (fixed: re-audit after banners); run 39726660079 green and `main`
  fast-forwarded to `f01e4ee`. Closed #161, #162, #164, #166, #168, #197, features F7.1–F7.4
  and E7 (#153). Open for the user: a VoiceOver game by hand. Next is E4 (#97 Specify).
- 2026-10-22: E4 started on branch `005-computer-opponent`. #97 done:
  `specs/005-computer-opponent/spec.md`, 5 stories, 28 functional requirements traced to #103–#113
  and #190, 10 success criteria, checklist 16/16. Setup can now start computer games, with the
  FRD's first-use defaults (Computer, Easy, Light) and choices remembered when a game starts. The
  setup and audit requirements have no board task yet (#101 assigns them). Three assumptions go to
  #98 Clarify.
- 2026-10-22: #98 done. Three clarifications: strength is proven by matches between the levels
  (at least 100 games per pairing, the stronger level scoring at least 70%) plus a playtest; about
  0.5 s before each further jump of a computer chain; the computer's move waits while Rules or
  Settings is open. Next is #99 Plan.
- 2026-10-22: #99 done. `specs/005-computer-opponent/plan.md` with research R1–R14, data model,
  contracts (`computer-player.md`, `computer-turn.md`) and quickstart; Constitution Check passes.
  Profiled first: through the public API the engine applies about 175,000 steps per second in
  Release and 11,000 in Debug, most of the time spent allocating arrays; an allocation-free turn
  generator prototype reproduced the published counts to 10 turns at about 25 million turns per
  second. So the search gets its own generator, with `GameState` as the referee for every step
  played. Strength matches run in Release in a new parallel CI job, `engine-strength`. FR-027
  aligned: the thinking state is too short to audit. Next is #100 Tasks.
- 2026-10-22: #100 done: `specs/005-computer-opponent/tasks.md`, 35 tasks, test-first, by story.
  `/speckit-analyze` found 6 issues (1 high: Debug-run engine tests would have searched at Hard's
  full node limit, so they now use small internal `SearchLimits` and Hard at full strength runs
  only in the Release strength tests); all fixed. #101 done: every E4 board task lists its task
  IDs; added #198 (computer games in setup, F4.2), #199 (strength matches in a Release CI job,
  F4.1) and #200 (slice validation and docs, F4.3, after #113). F4.0 (#96) closed. Backlog is now
  150 tasks. Next is implementation, starting with T001.
- 2026-10-22: E4 US1 done (T001–T015, commit `ae8e4ed`, CI run 39775315919 green). The engine
  gets an allocation-free `TurnGenerator` (published counts, 1,000-position cross-check) and
  `ComputerPlayer` (alpha-beta over complete turns, iterative deepening, capture extension,
  repetition and no-progress draws; 3.3–4.6 million nodes per second in Release); the game screen
  plays the computer's turn through the `ComputerOpponent` and `TurnPacer` seams (0.5 s thinking
  minimum, 0.5 s between jumps, board locked, 0.8 s search limit off the main actor); setup starts
  computer games with the FRD defaults and remembers choices on start. 192 tests pass. Found: a
  UI test cannot see the half-second thinking header (unit tests and previews cover it), and with
  Computer chosen the audit's edge-cut false positive moved to Start (exception widened). Closed
  #104, #107, #108, #109, #198. All levels still play alike until US2.
- 2026-10-22: Session close-out. E4 specified, planned, reconciled and US1 implemented; next is
  US2 (T016–T021). HANDOFF.md updated with the E4 lessons (profile first, approachable
  concurrency and `@concurrent`, `swift test` now lints, timing tests without waiting, sub-second
  UI states) and next steps. Local `main` was 35 commits behind GitHub's and was fast-forwarded;
  deleting the merged branches 002–004 is left to the user.
- 2026-10-22: E4 US2 (T016–T020) implemented; #103, #105 and #199 In Progress. The levels take
  research R4's starting values (Easy depth 2, margin 40; Medium depth 4, margin 8; Hard depth
  16, 1,500,000 nodes, only exact ties), and the root draws among turns within the margin with
  the seed. The new Release-only `CheckersEngineStrengthTests` play 100 games per pairing: Medium
  90 of 100 against Easy, Hard 99 of 100 against Medium, every step legal; Hard's slowest turn
  419 ms. CI gains the `engine-strength` job, and `CI gate` requires it. 199 tests pass in the
  blocking plan.
- 2026-10-22: E4 US2 closed out. CI run 39841996479 passed on `59ab67b`; `engine-strength` took
  4.5 minutes and matched the Mac's results exactly. #103, #105, #199 and F4.1 (#102) Done; T021
  checked off. Next is US3 (#110).
- 2026-10-22: E4 US3 (T022–T023) implemented; #110 In Progress. Resigning cancels the computer's
  turn, leaving already did, and its next step waits while Rules or Settings covers the game,
  then comes after a fresh 0.5 s pause (`ScreenCover`, wired to the router's path). A live test
  shows the main actor stays free during a Hard search. `GameSession`'s display queries moved to
  `GameSession+Display.swift` to stay within SwiftLint's length limits. 206 tests pass.
- 2026-10-22: CI run 39848881318 failed on US3's timed main-actor test: on the 3-core runner the
  other suites held the shared main actor through the whole search. The test now checks order
  (a probe queued after the search runs before it ends), not time.
- 2026-10-22: E4 US4 (T024–T026) implemented; #112 and #113 In Progress. Against the computer,
  Undo takes back turns until it is the player's turn (the computer's reply, its thinking or its
  partial chain, and the player's turn), cancelling the computer's turn first, and is unavailable
  until the player has moved (research R9). 213 tests pass.
- 2026-10-22: E4 US5 (T027–T028) implemented; #190 In Progress. VoiceOver announces each
  computer step once with E7's sentences, without "Jump again." in its chain, and focus stays
  where the player left it (`GameText.computerFollowUp`). 219 tests pass.
- 2026-10-22: CI run 39851771770 passed (US3's fix and US4) and run 39857462543 (US5): #110,
  #112, #113, #190 and F4.2 (#106) Done. Polish (T029–T033, #200 In Progress): the audit covers
  a computer game on the player's turn and with the result panel, all 12 audits pass on the
  iPhone 17 and on the iPhone SE at the largest text in Dark Mode; with Reduce Motion on the
  system spinner kept turning, so the game shows a still hourglass then. `GameSession`'s
  computer turn moved into an extension (class body 154 of 250 lines). 221 tests pass; the
  strength matches repeat their results. `checkers/CLAUDE.md` and the engine contract updated.
- 2026-10-22: E4 Computer opponent closed out. CI run 39861850824 passed on `a83be7c`
  (`engine-strength` 5.4 minutes, results unchanged). #200, F4.3 (#111) and E4 (#95) Done; all
  35 tasks of `specs/005-computer-opponent/` checked off; `main` fast-forwarded to the close-out
  commit. Next is E5 Saving and statistics.
- 2026-10-22: E5 started on branch `006-saving-and-statistics`. Spec written (#116 Done, #117
  In Progress): 4 user stories, 26 requirements traced to #72, #122–#127, #129–#131 and #189;
  leaving a game no longer asks (it stays saved), and Start asks "Abandon current game?" when a
  saved game exists.
- 2026-10-22: E5 spec clarified (#117 Done, #118 In Progress): an interrupted turn keeps the
  player's unfinished chain and restarts the computer's turn; an unreadable save is reported once by
  an alert on Home; an unreadable record starts again from zero, logged.
- 2026-10-22: E5 plan written (#118 Done, #119 In Progress): `GameState` becomes `Codable` in the
  engine with validation; the saved game and the record are JSON in `UserDefaults` behind
  protocols (a 220-turn game is about 23 KB and codes in about 2 ms); UI tests set saved data
  through launch arguments; no constitution violations.
- 2026-10-22: Session close-out. E5's `tasks.md` written (29 tasks: Setup and Foundational T001–T007,
  US1 T008–T012, US2 T013–T015, US3 T016–T019, US4 T020–T022, Polish T023–T029); #119 stays In
  Progress until `/speckit-analyze` has run. HANDOFF.md updated with the E5 lessons (no Spec Kit
  branch hook, measure before choosing storage, launch arguments for test data, persisted data in
  UI tests) and next steps.
- 2026-10-22: #119 done. `/speckit-analyze` on E5 found 15 problems, all fixed in the slice
  documents. Critical: an unreadable record was reset silently (Constitution IV.3); Home now tells
  the player once, added to the FRD as FR-STAT-06 (`FRD.md` 1.2). High: existing tests the slice
  would break had no task (leave confirmation, Statistics placeholder, direct Start taps). Medium
  and low: leaving between the computer's jumps, a chain saved in the background, FR-PRIV-01 named
  by a test, audits of the alerts, version 1 fixtures, launch arguments checked first.
- 2026-10-22: #120 and F5.0 (#115) done. Every E5 board task lists its Spec Kit task IDs; added
  #201 (validate the slice and update docs, F5.2, after #131); FR-STAT-06 added to #128 and #129,
  and FR-NAV-03 to #121 and #189. Backlog: 8 epics, 41 features, 151 tasks.
- 2026-10-22: E5 Setup, Foundational and US1 done in code (T001–T012, commits `93df603` and
  `5018d46`): `GameState` coding with validation, the saved-game and record stores, saving after
  every turn, on Home and in the background, Continue on Home, and no leave question; the full
  blocking plan passes locally (237 tests). Launch arguments confirmed in the simulator (T001).
  #122–#125 and #189 move to Done once CI run 39895348869 is green (still running at the session
  close-out). US2's tests are written but uncommitted until T015. Session close-out: HANDOFF.md
  updated with the E5 implementation lessons and next steps.
- 2026-10-23: CI run 39895348869 green on `5018d46` (E5 Setup, Foundational and US1);
  #122–#125 and #189 moved to Done with a comment each. E5: 10/17 tasks; F5.1 stays open
  for #126, #127 and #72.
- 2026-10-23: E5 US2 (T013–T015, commit `cab8db6`): Start asks "Abandon current game?" while
  a game is saved, and a finished game is no longer saved (the session sends `ended` once).
  `scripts/test.sh` passes locally (243 tests) and CI run 39949087079 is green; #127 and #72
  moved to Done. E5: 12/17 tasks; F5.1 stays open for #126 (US4).
- 2026-10-23: E5 US3 started: #129 and #130 moved to In Progress.
- 2026-10-23: E5 US3 (T016–T019) written and committed (`3bc52eb`): the record counts each
  finished game against the computer once at its difficulty, and Statistics replaces its
  placeholder. US3's test set passes locally (24 unit and 8 UI tests); the full blocking plan
  was left to CI. Session close-out: HANDOFF.md updated with the US2 and US3 lessons and next
  steps; #129 and #130 stay In Progress until that run is green.
- 2026-10-23: CI run 39954174275 green on `68c58c6` (US3 at `3bc52eb` plus the close-out):
  252 tests in the blocking plan. T016–T019 checked off; #130 moved to Done, #129's US3 part
  noted (it stays open for US4). E5: 13/17 tasks. US4 started: #126 moved to In Progress.
- 2026-10-23: E5 US4 (T020–T022) written and committed: an unreadable saved game is cleared and
  an unreadable record restarts from zero and is saved, each reported once by an alert on Home,
  the saved game's first. A third UI test (both damaged) found the second alert never showed when
  presented in the update that closed the first; Home now presents each from a `.task(id:)`.
  `scripts/test.sh` passes locally (259 tests); #126 and #129 move to Done once CI is green.
- 2026-10-23: CI run 40023240169 on `216c170` failed only on the engine's wall-clock SC-004
  check (10.5 s against 10 s) on a slow runner; the engine was unchanged, and a rerun passed with
  259 tests. #126, #129 and F5.1 (#121) moved to Done (comments posted, closed). E5: 15/17 tasks.
  Added #202 (T030 in `tasks.md`, under F5.2, before #201): the check now times the counting
  thread's CPU time; locally, with every core busy, the wall-clock version failed at 10.02 s and
  the CPU-time version passes (6.92 s). Backlog: 152 tasks.
- 2026-10-23: CI run 40031135343 green on `16ecf98` (US4 close-out and T030): 259 tests. #202
  moved to Done. E5: 16/18 tasks; Polish (#131, #201) is next.
- 2026-10-23: E5 Polish (T023–T028; #131 In Progress): the audit covers six new states (Home
  with and without Continue, Statistics with a record, the abandon alert, both restore alerts);
  system alerts' texts are allow-listed (they scale on screen, the audit says otherwise); all 17
  audits pass on the iPhone 17 and on the iPhone SE at the largest text in Dark Mode.
  `scripts/test.sh` passes with 264 tests; the strength matches repeat E4's results; saving a
  188-turn game takes 1.2 ms in Debug (SC-006); all 18 FRD IDs of the slice are named by tests.
  `checkers/CLAUDE.md` describes saving and statistics. T029 (CI, close E5, `main`) is next.
- 2026-10-23: E5 Saving and statistics done. CI run 40040004817 green on `f5cbf26` (264 tests,
  both jobs). #131, #201, F5.2 (#128) and E5 (#114) moved to Done (comments posted, closed); all
  30 tasks of `specs/006-saving-and-statistics/tasks.md` checked off; `main` fast-forwarded to
  the close-out commit. Backlog: 32/41 features, 122/152 tasks. Next is E6 (#134 Specify).
- 2026-10-23: Merged branches `002-rules-engine` to `006-saving-and-statistics` deleted, locally
  and on GitHub (`006-…` once E6's branch existed).
- 2026-10-23: E6 started on branch `007-settings-themes-sound-and-rules` (#132, F6.0 #133 In
  Progress). #134 done: `specs/007-settings-themes-sound-and-rules/spec.md`, 4 user stories (move
  hints, Rules, board themes, sound), 27 requirements traced to #140–#142, #144, #145, #147, #148
  and #150–#152, 9 success criteria, checklist 16/16. Measured: the prototype's Modern and Playful
  boards fail E7's 3:1 contrast, so the themes keep only their look. Three assumptions go to #135
  Clarify.
- 2026-10-23: #135 done. Four clarifications: the four sounds are original, generated by a script
  kept with the app and approved by ear; a theme changes only the board (also in the Settings and
  Rules pictures); a setting that cannot be read takes its default, logged, without an alert;
  Rules is one scrolling page of seven headed sections. Next is #136 Plan.
- 2026-10-23: #136 done. `specs/007-settings-themes-sound-and-rules/plan.md` with research
  R1–R13, data model, contracts (`settings-and-sound.md`, `screens.md`, `rules-content.md`) and
  quickstart; Constitution Check passes before and after design. Measured first: three
  `UserDefaults` keys read in 2.4 µs, set in UI tests by typed launch arguments (`<false/>`);
  Modern and Playful palettes that pass every contrast pair in light and dark; a Python script
  that writes four original sounds (0.12–1.2 s, 176 KB, byte-identical on repeat, checked in CI);
  audio players load in 107 ms and play calls take 11–69 ms on the Mac, so playback runs in an
  actor in the `.ambient` category. Every Rules picture is an engine position, its claim checked
  with the engine; the text is 364 words. Spec aligned: Rules' undo and resign section shows the
  game menu's items instead of a board (FR-021). Next is #137 Tasks.
- 2026-10-23: #137 in progress. `specs/007-settings-themes-sound-and-rules/tasks.md`: 35 tasks,
  test-first, by story (Setup and Foundational T001–T005, US1 T006–T010, US2 T011–T015, US3
  T016–T021, US4 T022–T028, Polish T029–T035); the sound recipes went into the contract so the
  script can be rebuilt. `/speckit-analyze` found 12 problems, none critical, not yet applied.
  High: a sound failure at run time is only logged (Constitution IV.3; the user decides how it is
  shown); `BoardTheme`'s names in Foundational would add catalog keys that E3's
  `prototypeStringsRemoved` forbids until US3. Medium: `ResultPanel`'s previews use
  `Palette.….color`; new value types need `nonisolated`; whether Rules pictures show hint rings;
  `init(saved:)` lives in `GameSession+Saving.swift`.
- 2026-10-23: Session close-out. E6 specified, clarified, planned and tasked on
  `007-settings-themes-sound-and-rules`; #137 stays In Progress until the analysis findings are
  applied. HANDOFF.md updated with the E6 lessons (deleted designs in git history, contrast by the
  test's pairs, typed launch arguments, audio setup cost, checking positions with the engine,
  strings in the story whose test changes, `nonisolated` value types) and next steps. Merged
  branches `002-…` to `006-…` deleted by the user.
- 2026-10-24: #137 done: the 12 `/speckit-analyze` findings applied (9b881b9, CI run
  40066363455). High: a sound failure at run time shows "Sound effects aren't available right
  now." in Settings and the next sound tries again (the user's choice; `FRD.md` 1.3 adds
  FR-SND-05, spec FR-017); `BoardTheme`'s names move to US3. Medium and low: `ResultPanel`'s
  previews, `nonisolated` value types, hint rings in the Rules pictures, `init(saved:)`'s file,
  the plan's source tree, research R13, and the checks by hand. Next: #138.
- 2026-10-24: #138 done, closing F6.0 (#133): every E6 board task lists its Spec Kit task IDs, and
  the requirement lines gained the spec's traceability IDs (FR-SND-05 on #146 and #148). #203
  added under F6.4 for setup and validation (T001, T002, T029–T035), after #142 and #152. Backlog
  now 153 tasks (#1–#203). Next: E6 implementation from T001.
- 2026-10-24: E6 implementation started. Setup and Foundational (T001–T005: baseline 264 tests,
  logging categories, the no-permission test, the settings store and `AppSettings`; #140 Done)
  and US1 (T006–T010: Settings with the move hints switch) on the branch, CI run 40069158202
  green. US2 (T011–T015: the Rules screen, its texts checked word for word against the contract)
  pushed at the session's close-out. US3 (T016–T020) is on the local branch
  `wip/007-us3-themes` with the US4 drafts; its Settings audit fails on the Classic theme row.
  Session close-out: HANDOFF.md updated.
- 2026-10-24: US2's CI run 40071432056 passed every test but failed `CI gate`: `build-and-test`
  reached its 30-minute limit during "Launch timing" (US2's UI tests added about 50 s, and the
  runner was about 15% slower). #204 (T036) added under F6.4 and In Progress: the limit is now 45
  minutes, and its push re-runs CI for US2's code. Backlog now 154 tasks (#1–#204).
- 2026-10-24: CI run 40116301945 green on `3b8ba4d` (`build-and-test` 24 of 45 minutes): #204,
  #150 and #151 Done, `main` fast-forwarded to `3b8ba4d`. US3 (T016–T020) brought onto the
  slice branch from `wip/007-us3-themes`; the Settings audit's contrast failures came from the
  inline picker merging each row's preview and name into one text element, so the theme rows
  are buttons with the selected trait (research R11, contract updated). 294 tests pass locally;
  pushed, CI to check. #144 waits for T021, #145 closes once CI is green.
- 2026-10-24: CI run 40121012315 green on `20096e7` (`build-and-test` 27 of 45 minutes): #145
  Done, `main` fast-forwarded to `20096e7`. T021's review page sent to the user. US4 (T022–T027)
  started (#146, #147, #148 In Progress) and pushed: `scripts/make-sounds.py` and the four sounds
  (R6's sizes, byte-identical on a rerun), `SoundEffect`, `SoundBank`, `AudioSoundPlayer`, a sound
  per step and resignation, the Sound section and its notice. E3's `NoWebContentTests` now allows
  exactly the four sounds; the Settings audit's edge-cut report moved to the Game section and got
  an allow-list row, as on setup. 309 tests pass locally; CI to check. #141 and #148 close once
  it is green; #147 waits for T028, #144 for T021.
- 2026-10-24: the user approved Modern and Playful as they are (T021, `validation.md` §4): #144
  and F6.2 (#143) Done. The local branch `wip/007-us3-themes` was deleted by the user. Left in
  E6: CI for US4, the listening review (T028), and Polish.
- 2026-10-24: the user approved the four sounds as they are (T028, `validation.md` §5); #147
  closes with #148 and #141 once US4's CI is green. Next: Polish (T029–T035).
- 2026-10-24: US4's CI run 40124926324 failed before building: the new runner image found no
  iOS simulator; the failed jobs were rerun. Polish T029–T030 done locally: audits of Settings
  (also at the largest size), Rules at its end and games in Modern and Playful; Settings'
  navigation bar made opaque; the audit allow-list gained text hidden under the navigation bar.
  One unnamed contrast report stays open on the iPhone SE at the largest size in Dark Mode.
- 2026-10-24: US4's rerun (40124926324, attempt 2) green on the same runner image
  (`build-and-test` 32 of 45 minutes): #141, #147, #148 and F6.3 (#146) Done, `main`
  fast-forwarded to `646089b`. The T021, T028 and T029–T030 commits pushed; #142 and #152 close
  once their run is green.
- 2026-10-24: Polish T031–T034 done on the branch: format, script, catalog and the blocking
  tests pass with zero warnings (313 tests); `checkers/CLAUDE.md` describes settings, themes,
  sound and rules; the quickstart is recorded (all 22 FRD IDs in tests, cold launch 2.085 s
  against the 3.635 s baseline; the iPhone and VoiceOver checks left for the user); HANDOFF.md
  and this plan reviewed. Next: T035, the final CI run and `main`.
- 2026-10-24: CI run 40128348379 failed on the scrolled largest-size Settings audit: text under
  the navigation bar, measured wherever the swipe stopped (its recording shows the Sound header
  cut by the bar). The scrolled audit was dropped (the top is audited at the largest size; the
  default size covers the rest), and with it the opaque bar and the allow-list rule it had led
  to; all audits pass twice on the iPhone 17 and on the iPhone SE at the largest size in Dark
  Mode, so nothing stays open there.
- 2026-10-24: **E6 done.** CI run 40130998987 green on `d85df26` (`build-and-test` 32 of 45
  minutes); `main` fast-forwarded to `d85df26`; #142, #152, #203, F6.1 (#139), F6.4 (#149) and
  the epic (#132) Done (T035). Progress: 37/41 features, 139/154 tasks; only E8 is left. Close-out
  review: risks revised (E6's sound tests pass on CI, the allow-list has three entries, CI run
  times); the user's open checks gathered under Next up. Next: E8 Release 1.0 (#169).
- 2026-10-24: Session close-out: HANDOFF.md updated (current state with E6 done, lessons
  learned from E6's CI and Polish, next steps: E8 with Spec Kit, the user's open checks); this
  plan reviewed against the close-out checklist (board matches, nothing in progress, Next up,
  risks and change log current).
- 2026-10-24: E8 started on branch `008-release-1-0` (#169, F8.0 #170 and #171 In Progress).
  Next up notes that `main` is at `0109e93` (the E6 close-out commit landed after `d85df26`).
- 2026-10-24: E8 spec written (#171 Done, #172 In Progress): `specs/008-release-1-0/spec.md`, 6
  user stories (every promise verified; fast and smooth on a real iPhone; diagnostics after
  release; icon and store page; TestFlight beta round; submitted and approved), 31 requirements, 10
  success criteria. Settled with the user first: paid developer account, device checks on their
  iPhone, a scripted original icon, GitHub Pages for the privacy and support pages, the store name
  chosen in App Store Connect, bundle ID kept, free everywhere, uploads with an API key outside
  the repository, TestFlight with a few external testers, one release checklist gathering every
  open hand check, manual release; E8 ends at approval. Found while writing: the iPhone is an
  iPhone 16 on iOS 27.0.1, and the Home Screen name is the lowercase "checkers".
