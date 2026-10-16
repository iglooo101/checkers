# Execution Plan

Last updated: 2026-10-16 · Board: [Checkers project](https://github.com/users/iglooo101/projects/1/views/1) · Source: `FRD.md` v1.0, constitution v1.0.0

This file tracks what is in progress and what is left to finish the project. It mirrors the
GitHub project board; when they disagree, fix both in the same change.

## How this file is maintained

- **Every board change updates this file in the same step**: starting a task (In Progress),
  finishing it (Done), and adding, splitting or closing issues.
- **Every close-out reviews and revises the whole file**: closing a task, feature or epic,
  finishing a Spec Kit slice, and ending a session (with `HANDOFF.md`).
- **Git**: solo repo. Work on a feature branch, fast-forward `main` locally and push; no pull
  requests unless needed. CI does not run for documentation-only changes.
- **Each epic is one Spec Kit slice.** Its `Fx.0 Specification` feature runs specify → clarify →
  plan → tasks/analyze, then the board tasks are reconciled with `tasks.md`. Implementation
  features start only after `Fx.0` is closed, and are built with `/speckit-implement`.

### Close-out checklist

1. Board: item status matches reality; closed issues are Done; new work has issues.
2. Progress table and backlog checkboxes below match the board.
3. In progress and Next up are current.
4. Risks and open items: add new ones, remove resolved ones.
5. Add a dated line to the change log.

## Progress

| Epic | Issue | Milestone | Priority | Features done | Tasks done | Status |
|---|---|---|---|---|---|---|
| E1 Project foundation | #1 | M1 Foundation | P0 | 0/6 | 0/21 | Todo |
| E2 Rules engine | #29 | M2 Playable two-player game | P0 | 0/6 | 0/21 | Todo |
| E3 Game experience | #57 | M2 Playable two-player game | P0 | 0/8 | 0/29 | Todo |
| E4 Computer opponent | #95 | M3 Computer opponent | P1 | 0/4 | 0/14 | Todo |
| E5 Saving and statistics | #114 | M4 Feature complete | P1 | 0/3 | 0/14 | Todo |
| E6 Settings, themes, sound and rules | #132 | M4 Feature complete | P1 | 0/5 | 0/15 | Todo |
| E7 Accessibility | #153 | M4 Feature complete | P1 | 0/5 | 0/10 | Todo |
| E8 Release 1.0 | #169 | M5 Release 1.0 | P2 | 0/4 | 0/14 | Todo |
| **Total** | | | | **0/41** | **0/138** | |

## In progress

Nothing yet.

## Next up

1. Merge `docs/frd` into `main` with a fast-forward (housekeeping; not on the board). PR #188
   is open for it and is marked merged once `main` contains its commits.
2. #3 E1 Specify: run `/speckit-specify` for the project foundation slice, then
   #4 Clarify, #5 Plan, #6 Tasks + analyze, #7 Reconcile.

## Order and dependencies

| Epic | Depends on |
|---|---|
| E1 Project foundation | Nothing. It blocks every other epic (test targets, CI and Swift 6 come before feature code). |
| E2 Rules engine | E1. |
| E3 Game experience | E2 (the board UI drives the rules engine). |
| E4 Computer opponent | E2 (search uses move generation) and E3 (computer turn in the game screen). |
| E5 Saving and statistics | E2 (game snapshot), E4 (resume during the computer's turn, record vs computer). |
| E6 Settings, themes, sound and rules | E3 (themes, sound and settings act on the game screen). |
| E7 Accessibility | E3 (board VoiceOver); announcements of the computer's moves also need E4. |
| E8 Release 1.0 | All other epics. |

E5, E6 and E7 can run in any order once their dependencies are done.

## Risks and open items

- Constitution values inferred from the codebase still need confirming (#27).
- `docs/frd` (FRD, this plan and handoff updates) is not merged into `main` yet (PR #188).
- CI must skip Markdown-only changes while still reporting its required check, or docs-only
  pushes to `main` get blocked (#10, #12).
- Board tasks are a first cut from the FRD; each slice's `tasks.md` will add, split or close
  tasks during reconciliation.
- FR-AI-02 (noticeable strength gaps) is partly subjective; the E4 plan needs a measurable
  test plus a playtest.

## Backlog

Checkboxes mirror the board: `[ ]` Todo, `[~]` In Progress, `[x]` Done. Sizes: S, M, L.

### E1 Project foundation (#1) · M1 Foundation · P0 · 0/21 tasks

**F1.0 Specification (Spec Kit)** (#2) · Constitution I–IX

- [ ] #3 E1 Specify: write spec.md with /speckit-specify · S
- [ ] #4 E1 Clarify: resolve open questions with /speckit-clarify · S
- [ ] #5 E1 Plan: write plan.md with /speckit-plan, including the Constitution Check · M
- [ ] #6 E1 Tasks: generate tasks.md with /speckit-tasks and check it with /speckit-analyze · S
- [ ] #7 E1 Reconcile this epic's board tasks with tasks.md · S

**F1.1 Test and CI infrastructure** (#8) · Constitution III

- [ ] #9 Add unit test target (Swift Testing) and UI test target (XCUITest) · M
- [ ] #10 Add GitHub Actions CI: build and test on an iOS simulator · M
- [ ] #11 Fail CI on compiler warnings and SwiftLint errors · S
- [ ] #12 Protect `main`: require green CI before code lands · S

**F1.2 Swift 6 and strict concurrency** (#13) · Constitution IV

- [ ] #14 Switch to Swift 6 language mode with complete strict concurrency · S

**F1.3 Lint and format** (#15) · Constitution I, IV, IX

- [ ] #16 Add SwiftLint with constitution rules · M
- [ ] #17 Add swift-format configuration and run it in build and CI · S

**F1.4 Privacy, logging and localization baseline** (#18) · FR-PRIV-01, FR-PRIV-02, FR-PLAT-03

- [ ] #19 Add PrivacyInfo.xcprivacy · S
- [ ] #20 Add OSLog Logger with bundle-ID subsystem and per-feature categories · S
- [ ] #21 Add String Catalog (Localizable.xcstrings) and treat its warnings as errors · S
- [ ] #22 Configure orientations: iPhone portrait only, iPad all orientations · S

**F1.5 Project structure and cleanup** (#23) · Constitution II

- [ ] #24 Delete template leftovers (Item.swift, stray Assets.xcassets/CheckersApp.swift) · S
- [ ] #25 Create local Swift package `CheckersEngine` with its own test target · M
- [ ] #26 Amend tasks-template.md so tests are mandatory · S
- [ ] #27 Confirm inferred constitution values (app description, iPad support, 400 ms launch budget) · S
- [ ] #28 Add cold-launch performance test baseline (XCTApplicationLaunchMetric) · S

### E2 Rules engine (#29) · M2 Playable two-player game · P0 · 0/21 tasks

**F2.0 Specification (Spec Kit)** (#30) · FRD §8, §9, §10

- [ ] #31 E2 Specify: write spec.md with /speckit-specify · S
- [ ] #32 E2 Clarify: resolve open questions with /speckit-clarify · S
- [ ] #33 E2 Plan: write plan.md with /speckit-plan, including the Constitution Check · M
- [ ] #34 E2 Tasks: generate tasks.md with /speckit-tasks and check it with /speckit-analyze · S
- [ ] #35 E2 Reconcile this epic's board tasks with tasks.md · S

**F2.1 Board model and starting position** (#36) · FR-RULE-01, FR-SETUP-06

- [ ] #37 Board, square and piece types with a–h / 1–8 coordinates · S
- [ ] #38 Standard starting position: 12 men per side, Light to move · S

**F2.2 Move generation** (#39) · FR-RULE-02, FR-RULE-03, FR-RULE-04, FR-RULE-05

- [ ] #40 Man moves one square diagonally forward · S
- [ ] #41 Man captures diagonally forward · S
- [ ] #42 King moves and captures in all four directions (no flying kings) · M
- [ ] #43 Mandatory capture: only captures are legal when one exists (any chain, not the longest) · S

**F2.3 Capture chains and crowning** (#44) · FR-RULE-06, FR-RULE-07, FR-CHAIN-01, FR-CHAIN-02, FR-CHAIN-03

- [ ] #45 Apply a capture one jump at a time with chain-continuation state · M
- [ ] #46 Crowning on the far row ends the turn, including mid-chain · S

**F2.4 Game state and endings** (#47) · FR-END-01, FR-END-02, FR-END-03, FR-END-04, FR-END-05

- [ ] #48 Game state: board, side to move, pending chain, outcome · M
- [ ] #49 Loss when the side to move has no legal move (or no pieces) · S
- [ ] #50 Draw by threefold repetition (same position, same side to move) · M
- [ ] #51 Draw by no progress: 40 moves per side without capture or man move · S
- [ ] #52 Resignation outcome · S

**F2.5 Undo history** (#53) · FR-UNDO-01, FR-UNDO-02, FR-UNDO-05, FR-UNDO-06, FR-UNDO-07

- [ ] #54 Turn history that restores full state, including draw counters · M
- [ ] #55 Undo mid-chain restores the position from before the chain · S
- [ ] #56 Undo is unavailable after the game has ended · S

### E3 Game experience (#57) · M2 Playable two-player game · P0 · 0/29 tasks

**F3.0 Specification (Spec Kit)** (#58) · FRD §4–7, §9, §10

- [ ] #59 E3 Specify: write spec.md with /speckit-specify · S
- [ ] #60 E3 Clarify: resolve open questions with /speckit-clarify · S
- [ ] #61 E3 Plan: write plan.md with /speckit-plan, including the Constitution Check · M
- [ ] #62 E3 Tasks: generate tasks.md with /speckit-tasks and check it with /speckit-analyze · S
- [ ] #63 E3 Reconcile this epic's board tasks with tasks.md · S

**F3.1 App shell and navigation** (#64) · FR-NAV-01, FR-NAV-02, FR-NAV-03, FR-NAV-04, FR-GAME-06

- [ ] #65 Home screen with New game, Statistics, Rules, Settings and conditional Continue · M
- [ ] #66 Game screen menu: Undo, Resign, Rules, Settings, Home · M
- [ ] #67 Remove the HTML screens, move.wav reference and WKWebView code · S
- [ ] #68 Accessibility pass: Home and navigation (Dynamic Type, Dark Mode, VoiceOver labels, previews) · S

**F3.2 Game setup** (#69) · FR-SETUP-01, FR-SETUP-02, FR-SETUP-03, FR-SETUP-04, FR-SETUP-05

- [ ] #70 Setup screen: opponent, difficulty and side (Light, Dark, Random) · M
- [ ] #71 Preselect last-used choices; first-use defaults Computer, Easy, Light · S
- [ ] #72 "Abandon current game?" confirmation when a saved game exists · S
- [ ] #73 Accessibility pass: Game setup · S

**F3.3 Board view** (#74) · FR-GAME-01, FR-GAME-02, FR-GAME-03, FR-GAME-04, FR-GAME-05, FR-GAME-07, FR-SND-04, FR-PLAT-02

- [ ] #75 SwiftUI board: 8×8 grid, men and kings, sized to fit (iPad portrait and landscape) · M
- [ ] #76 Board orientation: player's side at bottom vs computer; Light at bottom in two-player, no rotation · S
- [ ] #77 Turn indicator, including "capture required" · S
- [ ] #78 Accessibility pass: Game screen layout at accessibility5 and Dark Mode · S

**F3.4 Move input** (#79) · FR-MOVE-01, FR-MOVE-02, FR-MOVE-03, FR-MOVE-04, FR-MOVE-05

- [ ] #80 Game model (@Observable): selection rules, tested without UI · M
- [ ] #81 Tap a piece, then tap a target · S
- [ ] #82 Drag a piece onto a target; invalid drops return the piece · M
- [ ] #83 Tell the player a capture is required when they tap a piece that cannot capture · S

**F3.5 Move aids and chain interaction** (#84) · FR-AID-01, FR-AID-02, FR-AID-03, FR-AID-04, FR-CHAIN-02

- [ ] #85 Highlight movable pieces and legal targets when hints are on · S
- [ ] #86 Selected piece always visibly marked · S
- [ ] #87 Chain lock: only the jumping piece and its next jumps are available · S

**F3.6 Game end and result** (#88) · FR-END-02, FR-END-06, FR-END-07, FR-END-08

- [ ] #89 Resign with confirmation (human vs computer; side to move in two-player) · S
- [ ] #90 Result panel over the final position with outcome and reason, Play again and Home · M
- [ ] #91 Play again keeps opponent, difficulty and side; Random re-rolls the side · S
- [ ] #92 Accessibility pass: result panel and confirmations · S

**F3.7 Undo in the game** (#93) · FR-UNDO-01, FR-UNDO-02, FR-UNDO-06

- [ ] #94 Undo menu item with enable/disable rules; two-player undo takes back one turn · S

### E4 Computer opponent (#95) · M3 Computer opponent · P1 · 0/14 tasks

**F4.0 Specification (Spec Kit)** (#96) · FRD §11

- [ ] #97 E4 Specify: write spec.md with /speckit-specify · S
- [ ] #98 E4 Clarify: resolve open questions with /speckit-clarify · S
- [ ] #99 E4 Plan: write plan.md with /speckit-plan, including the Constitution Check · M
- [ ] #100 E4 Tasks: generate tasks.md with /speckit-tasks and check it with /speckit-analyze · S
- [ ] #101 E4 Reconcile this epic's board tasks with tasks.md · S

**F4.1 AI search** (#102) · FR-AI-01, FR-AI-02

- [ ] #103 Position evaluation function · M
- [ ] #104 Cancellable alpha-beta search off the main actor · L
- [ ] #105 Difficulty levels Easy, Medium, Hard with measurable strength gaps · M

**F4.2 Computer turn** (#106) · FR-AI-03, FR-AI-04, FR-AI-05, FR-AI-06, FR-MOVE-04

- [ ] #107 Computer turn controller: thinking indicator, 0.5–1 s pause, board input locked · M
- [ ] #108 Show the computer's capture chains one jump at a time · S
- [ ] #109 Computer makes the first move when it plays Light · S
- [ ] #110 UI stays responsive while thinking: menu, Undo and Home work · S

**F4.3 Undo against the computer** (#111) · FR-UNDO-03, FR-UNDO-04

- [ ] #112 Undo takes back the player's turn and the computer's reply; unavailable before the first move · S
- [ ] #113 Undo while the computer thinks cancels its turn · S

### E5 Saving and statistics (#114) · M4 Feature complete · P1 · 0/14 tasks

**F5.0 Specification (Spec Kit)** (#115) · FRD §12, §13

- [ ] #116 E5 Specify: write spec.md with /speckit-specify · S
- [ ] #117 E5 Clarify: resolve open questions with /speckit-clarify · S
- [ ] #118 E5 Plan: write plan.md with /speckit-plan, including the Constitution Check · M
- [ ] #119 E5 Tasks: generate tasks.md with /speckit-tasks and check it with /speckit-analyze · S
- [ ] #120 E5 Reconcile this epic's board tasks with tasks.md · S

**F5.1 Auto-save and resume** (#121) · FR-SAVE-01, FR-SAVE-02, FR-SAVE-03, FR-SAVE-04, FR-SAVE-05, FR-END-08, FR-NAV-02

- [ ] #122 Codable game snapshot: position, side, opponent, difficulty, undo history, counters · M
- [ ] #123 Saved-game store behind a protocol (live and in-memory fake) · M
- [ ] #124 Save after every turn and when the app goes to the background · S
- [ ] #125 Continue restores the game exactly; computer resumes if it was its turn · M
- [ ] #126 Unreadable save: discard, hide Continue, tell the player · S
- [ ] #127 Clear the saved game on game end and on abandon · S

**F5.2 Statistics** (#128) · FR-STAT-01, FR-STAT-02, FR-STAT-03, FR-STAT-04, FR-STAT-05, FR-SETUP-05, FR-UNDO-08

- [ ] #129 Record model and recording rules (wins/losses/draws per difficulty) · M
- [ ] #130 Statistics screen with empty state · M
- [ ] #131 Accessibility pass: Statistics · S

### E6 Settings, themes, sound and rules (#132) · M4 Feature complete · P1 · 0/15 tasks

**F6.0 Specification (Spec Kit)** (#133) · FRD §14, §15, §16

- [ ] #134 E6 Specify: write spec.md with /speckit-specify · S
- [ ] #135 E6 Clarify: resolve open questions with /speckit-clarify · S
- [ ] #136 E6 Plan: write plan.md with /speckit-plan, including the Constitution Check · M
- [ ] #137 E6 Tasks: generate tasks.md with /speckit-tasks and check it with /speckit-analyze · S
- [ ] #138 E6 Reconcile this epic's board tasks with tasks.md · S

**F6.1 Settings** (#139) · FR-SET-01, FR-SET-03, FR-SET-04, FR-AID-04

- [ ] #140 Settings store with defaults (Classic, sound on, hints on), persisted behind a protocol · S
- [ ] #141 Settings screen; changes apply immediately, including in a game in progress · M
- [ ] #142 Accessibility pass: Settings · S

**F6.2 Board themes** (#143) · FR-SET-02, FR-GAME-07

- [ ] #144 Classic, Modern and Playful themes as asset-catalog colors with dark variants · M
- [ ] #145 Theme picker with board previews · S

**F6.3 Sound effects** (#146) · FR-SND-01, FR-SND-02, FR-SND-03

- [ ] #147 Sound assets: move, capture, crowning, game end · S
- [ ] #148 Sound service behind a protocol that respects silent mode and volume · M

**F6.4 Rules screen** (#149) · FR-HELP-01, FR-HELP-02

- [ ] #150 Illustrated rules content: setup, moving, captures, chains, crowning, win/draw, undo/resign · M
- [ ] #151 Rules reachable from Home and the game menu · S
- [ ] #152 Accessibility pass: Rules · S

### E7 Accessibility (#153) · M4 Feature complete · P1 · 0/10 tasks

**F7.0 Specification (Spec Kit)** (#154) · FRD §17

- [ ] #155 E7 Specify: write spec.md with /speckit-specify · S
- [ ] #156 E7 Clarify: resolve open questions with /speckit-clarify · S
- [ ] #157 E7 Plan: write plan.md with /speckit-plan, including the Constitution Check · M
- [ ] #158 E7 Tasks: generate tasks.md with /speckit-tasks and check it with /speckit-analyze · S
- [ ] #159 E7 Reconcile this epic's board tasks with tasks.md · S

**F7.1 VoiceOver board** (#160) · FR-A11Y-01, FR-A11Y-02

- [ ] #161 Each square is a VoiceOver element: coordinate, contents, state ("c3, Light man, can move") · M
- [ ] #162 Double-tap to select and to move, including chains; UI test · M

**F7.2 VoiceOver announcements** (#163) · FR-A11Y-03

- [ ] #164 Announce moves (both sides), captures, crowning, turn changes, mandatory captures and results · M

**F7.3 Non-color cues** (#165) · FR-A11Y-05

- [ ] #166 Kings, selection and hints distinguishable without color in every theme · S

**F7.4 Accessibility audit automation** (#167) · FR-A11Y-04

- [ ] #168 UI test running performAccessibilityAudit() on every screen · M

### E8 Release 1.0 (#169) · M5 Release 1.0 · P2 · 0/14 tasks

**F8.0 Specification (Spec Kit)** (#170) · FRD §18

- [ ] #171 E8 Specify: write spec.md with /speckit-specify · S
- [ ] #172 E8 Clarify: resolve open questions with /speckit-clarify · S
- [ ] #173 E8 Plan: write plan.md with /speckit-plan, including the Constitution Check · M
- [ ] #174 E8 Tasks: generate tasks.md with /speckit-tasks and check it with /speckit-analyze · S
- [ ] #175 E8 Reconcile this epic's board tasks with tasks.md · S

**F8.1 Platform and privacy verification** (#176) · FR-PLAT-01, FR-PLAT-02, FR-PLAT-03, FR-PRIV-01, FR-PRIV-02

- [ ] #177 Verify no network requests, no permission prompts, no account or analytics · S
- [ ] #178 Verify iPhone portrait-only and iPad rotation on devices · S
- [ ] #179 FRD traceability check: every FR ID covered by a test or a manual check · S

**F8.2 Performance** (#180) · Constitution VII

- [ ] #181 Cold launch under 400 ms on a recent iPhone (release build) · S
- [ ] #182 Hitch-ratio check during play and AI turns · S

**F8.3 App Store delivery** (#183)

- [ ] #184 App icon and launch screen · M
- [ ] #185 App Store metadata, screenshots and privacy label (Data Not Collected) · M
- [ ] #186 TestFlight build and beta round · S
- [ ] #187 Submit for App Store review · S

## Change log

- 2026-10-16: Backlog created from `FRD.md` v1.0: 8 epics, 41 features, 138 tasks (#1–#187),
  nested as sub-issues and added to the board with Level, Epic, Priority and Size fields.
- 2026-10-16: #10 and #12 revised: no CI for documentation-only changes, and no pull requests
  (fast-forward merges keep CI results valid on `main`). Constitution-based issues now point to
  the constitution instead of the FRD.
