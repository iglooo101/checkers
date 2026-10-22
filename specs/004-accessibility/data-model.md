# Data Model: Accessibility

Phase 1 output for `specs/004-accessibility/plan.md`. Additions to E3's app types
(`specs/003-game-experience/data-model.md`); decisions in [research.md](research.md), exact texts
in [contracts/announcements.md](contracts/announcements.md).

## Value types

### SquareState (R1)

| Case | When |
|---|---|
| `none` | Any square once the game is over; a piece of the side not to move; a piece of the side to move that cannot move; an empty square that is not a target |
| `canMove` | A movable piece of the side to move that is not selected (only capturers when a capture is required; only the chain piece during a chain) |
| `selected` | The selected piece |
| `legalTarget` | An empty square that is a target of the selected piece |

States never depend on the hints setting (Clarifications).

### Announcement (R4)

The text of one announcement: a `LocalizedStringResource` built from two catalog sentences with
the template "%1$@ %2$@", or one sentence alone (the notice, a resignation's result).

## GameSession additions

| Field | Type | Notes |
|---|---|---|
| `announcer` | `any Announcer` | Injected; `AccessibilityAnnouncer` in the app, `RecordingAnnouncer` in tests and previews |
| `focusSquare` | `Square?` | The landing square of the last step, for VoiceOver focus (R2); cleared by undo and Play again |
| `state(of:)` | `SquareState` | Derived (R1) |
| `squareLabel(_:)` | `LocalizedStringResource` | Derived: coordinate, contents and state (R1) |

Announcements are made in `tap`, `drop`, `undo` and `resign` (contract: when to announce).

## Services

### Announcer (R3)

| Member | Notes |
|---|---|
| `announce(_ text: LocalizedStringResource)` | Speaks the text with VoiceOver; does nothing when VoiceOver is off |

Conformances: `AccessibilityAnnouncer` (live) and `RecordingAnnouncer` (keeps `announcements` in
order).

## Palette changes (R5)

| Color set | Before | After |
|---|---|---|
| `PieceDarkEdge` | `#6b4426` / `#8a5a36` | `#d9b48a` |
| `Selection` | `#1f6fd1` / `#4c9bff` | `#7fd3ff` |
| `Target` | `#1f6fd1` / `#4c9bff`, 85% | `#7fd3ff`, 85% |
| `Crown` | `#e8c46a` | removed |
| `CrownOnLight` | — | `#6b4426` |
| `CrownOnDark` | — | `#e8c46a` |

App colors outside the board palette, set by the audit (R6): `AccentColor` (unset, the system
blue) becomes `#0058c4` / `#66b2ff`, and the new `OnAccent` (`#ffffff` / `#001a33`) is the label
color of prominent buttons, so white-on-blue and blue-on-background text both reach 4.5:1.
