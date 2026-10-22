# Implementation Plan: Accessibility

**Branch**: `004-accessibility` | **Date**: 2026-10-22 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/004-accessibility/spec.md`

## Summary

Make the board fully usable with VoiceOver and without color, on top of E3's game screen. Square
labels gain their state ("can move", "selected", "legal target") as whole catalog sentences
decided by `GameSession`. VoiceOver double-taps keep using the same tap rules, and focus follows
each move to its landing square. `GameSession` announces every step, undo, notice and result
through an injected `Announcer`, one announcement per step built from two whole sentences. The
Classic palette gets new outline, selection, target and crown colors so every mark has at least
3:1 contrast against what it sits on (measured), checked by a contrast test, while Light and Dark
pieces stay apart by lightness (16:1). An accessibility audit UI test checks every screen and its
main states. Research: [research.md](research.md).

## Technical Context

**Language/Version**: Swift 6.2 (Xcode 26.3), Swift 6 language mode, complete strict concurrency;
app target default isolation is the main actor

**Primary Dependencies**: SwiftUI (`AccessibilityNotification`, `AccessibilityFocusState`),
`CheckersEngine` (E2), XCTest's `performAccessibilityAudit` for the audit; SwiftLintPlugins
(build-time, existing)

**Storage**: N/A

**Testing**: Swift Testing for descriptions, announcements, focus and contrast; XCUITest for labels
in the running app and the audit; one VoiceOver session by hand (SC-001)

**Target Platform**: iOS 26.2+, iPhone only, portrait

**Project Type**: mobile app (Xcode project) using the local engine package

**Performance Goals**: no change: labels and announcements are derived per tap; no animation

**Constraints**: every spoken text is a whole catalog sentence or a localizable template of whole
sentences (Constitution V.4); no hue-only cues; at least 3:1 contrast for every mark; no test-only
code in the app

**Scale/Scope**: about 4 changed and 2 new app files, 6 new test files; 20 functional requirements,
5 user stories

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|---|---|---|
| I. Native & Modern Apple Stack | Pass | SwiftUI accessibility APIs and `@Observable`; no UIKit, Combine or Dispatch. |
| II. Feature-Based Architecture | Pass | States and announcements are decided in `GameSession`; the view only binds labels and focus. `Announcer` is injected through a protocol with live and recording conformances (II.3). No new abstraction beyond that seam. |
| III. Test-First Quality | Pass | Each story's tests precede its implementation; scripted games check every square and announcement (SC-002, SC-003); the audit runs in the blocking test plan. Swift Testing for logic, XCUITest only for UI flows and the audit (III.2). |
| IV. Safety & Correctness | Pass | No force unwraps outside tests; no new error paths (announcements cannot fail visibly). |
| V. UX & Accessibility | Pass, the purpose of the slice | VoiceOver labels with state, announcements of game state, non-color cues, 3:1 contrast for marks, Dynamic Type and Dark Mode kept, and the audit test on every screen that V's verification names. |
| VI. Privacy & Security | Pass | No data, storage, network or permissions. |
| VII. Performance | Pass | Derived values only; no background work. |
| VIII. Simplicity & Dependencies | Pass | No dependencies. The palette changes are measured needs (R5), not speculation. |
| IX. Observability | Pass | No new logging needs. |
| Workflow gates | Pass | spec → clarify → plan → tasks → implement. |

**Gate result (pre-research)**: PASS. No violations.

### Dependency justification (Principle VIII)

| Dependency | Why Apple frameworks fall short | Maintenance | License | Added via |
|---|---|---|---|---|
| *(none added)* | | | | |

### Lint allow-list

| File | Rule | Reason |
|---|---|---|
| *(none)* | | The allow-list stays empty. |

### Audit allow-list

| Screen | Element | Issue type | Reason |
|---|---|---|---|
| Game setup, Computer chosen | Start (`setup.start`) while disabled | Contrast; Dynamic Type | The system dims a disabled control; WCAG exempts inactive controls from contrast. Start scales with Dynamic Type (checked on screen at the largest size), so the Dynamic Type report is wrong. |
| Game setup | A static text line the scrolling form cuts at the screen's edge | Dynamic Type, "partially unsupported" only | When the audit enlarges the text, the system form scrolls and the audit reports whichever line crosses the bottom edge (R6 findings). The lines scale and scroll into view. Allowed issues are logged in the test report. |

### Other recorded decisions

- **Spec alignment**: FR-020 (at least 3:1 contrast for every piece and mark) was added in planning
  after measuring the Classic palette (R5); SC-005 includes it.
- **Palette**: `PieceDarkEdge`, `Selection`, `Target` change and `Crown` splits into `CrownOnLight`
  and `CrownOnDark` (data model). E6's themes (#144) must pass the same contrast test.
- **Audit fixes** (R6): `AccentColor` `#0058c4` / `#66b2ff` and `OnAccent` for prominent button
  labels; primary text for the notice, placeholders, setup headers and computer note; an opaque
  result panel; the computer note under the opponent choice.
- **Announcement template** "%1$@ %2$@" joins two whole sentences; it is a localizable entry, not
  string concatenation in code (R4).
- **VoiceOver itself is not automatable** in XCUITest; double-tap activation shares the tested tap
  path and is checked once by hand (R7).

### Post-design re-check

Re-evaluated after Phase 1 ([data-model.md](data-model.md),
[contracts/announcements.md](contracts/announcements.md), [quickstart.md](quickstart.md)): no
violations. The design adds one injected service, derived values on the existing session, and
color changes justified by measurement. **Gate result (post-design)**: PASS.

## Project Structure

### Documentation (this feature)

```text
specs/004-accessibility/
├── plan.md              # This file
├── research.md          # Phase 0 decisions R1–R8
├── data-model.md        # SquareState, Announcer, session additions, palette changes
├── quickstart.md        # Validation scenarios
├── contracts/
│   └── announcements.md # Square descriptions, announcement texts, focus, audited screens
├── checklists/
│   ├── requirements.md  # Spec quality checklist
│   └── validation.md    # Quickstart results (written during implementation)
└── tasks.md             # Phase 2 output (/speckit-tasks)
```

### Source Code (repository root)

```text
checkers/checkers/
├── Features/Game/
│   ├── SquareState.swift          # new: none, canMove, selected, legalTarget
│   ├── Announcer.swift            # new: protocol, AccessibilityAnnouncer, RecordingAnnouncer
│   ├── GameSession.swift          # + state(of:), squareLabel(_:), focusSquare, announcements
│   ├── GameText.swift             # + 14 square sentences, step and follow-up sentences, template
│   ├── BoardView.swift            # labels from the session, accessibility focus binding
│   └── PieceView.swift            # crown colors by side
├── App/AppRouter.swift            # passes the live announcer to new sessions
└── Assets.xcassets/               # PieceDarkEdge, Selection, Target changed; CrownOnLight, CrownOnDark
checkers/checkersTests/
├── US1SquareDescriptionTests.swift
├── US2VoiceOverPlayTests.swift
├── US3AnnouncementTests.swift
├── US4ContrastTests.swift          # extends PaletteTests' color checks with WCAG contrast
└── Support/ScriptedGames.swift    # scripted games for SC-002 and SC-003
checkers/checkersUITests/
├── US1SquareLabelUITests.swift
└── US5AccessibilityAuditUITests.swift
```

**Structure Decision**: Everything stays in the E3 feature folders; the only new service is the
announcer next to the session that uses it.

## Complexity Tracking

No violations to justify.

## Follow-ups for other slices

- **E4 (#190)**: announce the computer's steps through the same `Announcer` and sentences; keep
  focus where the player left it during the computer's turn.
- **E5, E6 (#131, #142, #152)**: add the Statistics, Settings and Rules screens to the audit test.
- **E6 (#144)**: every theme passes `US4ContrastTests`; hints off must not change VoiceOver states.
