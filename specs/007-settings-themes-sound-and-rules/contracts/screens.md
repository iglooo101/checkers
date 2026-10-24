# Contract: screens, texts and identifiers (E6 changes)

Changes to `specs/003-game-experience/contracts/screens.md` (as changed by
`specs/006-saving-and-statistics/contracts/screens.md`). Texts are English, from the String
Catalog; identifiers are for UI tests. Behavior is in [settings-and-sound.md](settings-and-sound.md).

## Placeholders (E3 FR-003)

**Removed**: `PlaceholderView`, its identifier `placeholder.message`, and its two lines ("How to
play American checkers will be explained here.", "Board theme, sound effects and move hints will
be set here."). Home's and the game menu's Rules and Settings entries keep their texts and
identifiers and open the screens below.

## Settings (FR-001 to FR-005, FR-013, FR-017, FR-025)

A form, titled Settings, opened from Home (`home.settings`) and the game menu
(`game.menu.settings`); the back button returns where it was opened from.

| Section | Element | Text | Identifier |
|---|---|---|---|
| Board theme | Inline picker, one row per theme: preview (hidden from VoiceOver) and name; the chosen row has a checkmark | Classic · Modern · Playful | `settings.theme.classic`, `settings.theme.modern`, `settings.theme.playful` |
| Sound | Toggle | Sound effects | `settings.soundEffects` |
| Sound | Footer, only while `AppRouter.showsSoundNotice` (sound effects on, sounds unable to play) | "Sound effects aren't available right now." | `settings.soundUnavailable` |
| Game | Toggle, with footer | Move hints · "Rings the pieces that can move and dots the squares the selected piece can go to." | `settings.moveHints` |

- Each preview is a `BoardPicture` of the top-left 4 × 4 squares from Light's side, in that theme
  and the current appearance: Dark men on b8 and d8, a Dark king on a7, a Light man on c5 and a
  Light king on b6 (decorative; no marks).
- VoiceOver: "Modern, selected" (or not selected) for a theme row; "Sound effects, on"; "Move
  hints, off". The Sound section's notice is read as text after the switch.
- The notice appears and goes while Settings is shown, as `showsSoundNotice` changes
  ([settings-and-sound.md](settings-and-sound.md), "When sounds cannot play").
- At accessibility sizes the rows grow and wrap; the previews keep their size beside the name, or
  above it when the row is too narrow.

## Rules (FR-020 to FR-023, FR-025)

One scroll view, titled Rules, opened from Home (`home.rules`) and the game menu
(`game.menu.rules`). Seven sections in order; each has a heading (header trait), its text and its
pictures. Content: [rules-content.md](rules-content.md).

| Element | Identifier |
|---|---|
| Section heading | `rules.<id>.title` |
| Section text | `rules.<id>.text` |
| Board picture (one image element, labelled with its description) | `rules.<id>.picture`, then `rules.<id>.picture2` for a second |
| Undo and Resign illustration (one element: "The game menu's Undo and Resign.") | `rules.undoResign.picture` |

Section ids: `board`, `moving`, `capturing`, `chains`, `kings`, `ending`, `undoResign`.

- Pictures are full boards from Light's side, at the text column's width (at most 320 points),
  in the chosen theme. They take no input.
- The Undo and Resign illustration shows two menu-style rows: `arrow.uturn.backward` with "Undo",
  `flag` with "Resign", in primary text.
- All text is primary text; at accessibility sizes the text grows and the pictures stay at the
  column's width.

## Game screen (FR-003, FR-006, FR-009)

| Element | Change |
|---|---|
| Board | Drawn in the chosen theme; hint rings and target dots only while move hints are on |

## Audited states (FR-026, SC-007)

Added to `US5AccessibilityAuditUITests`: Settings; Settings at the largest accessibility size;
Rules at its top and scrolled to its end; a new two-player game in Modern and in Playful
(`-boardTheme modern`, `-boardTheme playful`), with a piece selected. The Rules and Settings
placeholder audits become the Rules and Settings audits. Settings with the sound notice is not
audited: UI tests cannot make sounds fail without test-only code; it is primary footer text like
the Game section's, and its preview is checked at `accessibility5` and in Dark Mode. An issue on a system component (the
form's toggles or picker) goes on the plan's audit allow-list with its reason.
