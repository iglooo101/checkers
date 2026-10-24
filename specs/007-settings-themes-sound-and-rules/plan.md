# Implementation Plan: Settings, Themes, Sound and Rules

**Branch**: `007-settings-themes-sound-and-rules` | **Date**: 2026-10-23 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/007-settings-themes-sound-and-rules/spec.md`

## Summary

Replace E3's Rules and Settings placeholders and finish the game's options, on top of the game
screen (E3), its contrast rules (E7), the computer opponent (E4) and saving (E5). Three settings
(theme, sound effects, move hints) are plain `UserDefaults` values behind a store protocol, read
per key with a logged fallback, and live in one `@Observable` `AppSettings` that the router hands
to every game session; reading them takes 2.4 µs (*measured*), so the first frame already has the
chosen theme. With hints off, the session's hinted pieces and targets are empty and nothing else
changes. Each theme is the same 12 board colors in its own asset-catalog folder; Modern and
Playful keep the prototype's look with colors measured to pass every contrast pair in both
appearances (weakest 5.64:1 and 4.16:1). A static `BoardPicture` draws the Settings previews and
the Rules pictures with the game's own piece view. Four original sounds come from a Python script
with a fixed seed (0.12 s to 1.2 s, 176 KB, reproducible and checked in CI); the session picks one
per step (game end, crowning, capture, move) and an actor plays it through prepared audio players
in the `.ambient` category, off the main actor (loading 107 ms and each play call 11–69 ms on the
Mac, *measured*). Rules is one scrolling page of seven sections whose pictures are engine positions,
each claim checked against the engine. Research: [research.md](research.md).

## Technical Context

**Language/Version**: Swift 6.2 (Xcode 26.3), Swift 6 language mode, complete strict concurrency;
app target default isolation is the main actor with approachable concurrency; Python 3 (standard
library only) for the sound script

**Primary Dependencies**: SwiftUI, Observation, Foundation (`UserDefaults`), AVFoundation
(`AVAudioPlayer`, `AVAudioSession`), `CheckersEngine` (unchanged); SwiftLintPlugins (build-time,
existing)

**Storage**: `UserDefaults.standard`, three new keys (`boardTheme`, `soundEffects`, `moveHints`)
beside E3's and E5's (R1)

**Testing**: Swift Testing for the store (defaults, per-key fallback against a temporary suite),
`AppSettings`, hints on and off in the session, the sound chosen for every kind of step and
ending (recording player, scripted games, manual pacer), the bundled sound files, every theme's
contrast pairs in light and dark, and the Rules content (pictures rebuilt and checked with the
engine, word count); XCUITest for Settings and Rules from Home and the game menu, a setting kept
after relaunch, and the audit; settings set through launch arguments (R10); a script test for the
sound recipes

**Target Platform**: iOS 26.2+, iPhone only, portrait

**Project Type**: mobile app (Xcode project) with the local engine package

**Performance Goals**: a setting's change shows when the game reappears (SC-001); a sound within
0.1 s of its step (SC-004; play calls off the main actor); no launch regression (SC-008: settings
read in 2.4 µs, sounds prepared after launch off the main actor)

**Constraints**: only the board is themed; one sound per step; no test-only behavior in the app;
whole sentences from the String Catalog; previews never touch storage or play sound (workflow
gate 4); the Rules text at most about 600 words (364 drafted)

**Scale/Scope**: about 13 new and 10 changed app files, 4 generated sound files, 24 new asset
colors (and Classic's 12 moved), 1 new script; 4 user stories, 27 functional requirements

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|---|---|---|
| I. Native & Modern Apple Stack | Pass | SwiftUI forms, toggles and picker; `@Observable` settings; AVFoundation for sound, in an actor; no Combine, Dispatch or threads. |
| II. Feature-Based Architecture | Pass | New `Settings`, `Sound` and `Rules` feature folders; the hints and sound rules live in `GameSession`, the settings in `AppSettings`, the Rules pictures' marks come from the engine; views stay thin. The store and the sound player are injected protocols with live and fake conformances (II.3, exempt from II.5); `UserDefaults.standard` and `AVAudioSession.sharedInstance()` are used only inside the live conformances (II.3). Types are structs and enums except `AppSettings` (shared observed state), the stores and players (state), and the `SoundBank` actor. |
| III. Test-First Quality | Pass | Each story's tests come first; the session is tested with the in-memory store and the recording player (III.4), the `UserDefaults` store against a temporary suite; acceptance tests name US1–US4; UI tests get settings through launch arguments (R10). |
| IV. Safety & Correctness | Pass | Typed `SoundError` (IV.2), every failure logged and the game goes on; an unreadable setting falls back to its default, logged, with no alert, because Settings shows the value and one tap restores it, which is the clear state and recovery path IV.3 asks for (spec Clarifications); no force unwraps; no `@unchecked Sendable`. |
| V. UX & Accessibility | Pass | System form controls; Rules headings with the header trait, pictures as labelled images; every mark keeps 3:1 contrast in every theme and appearance (R4, `US4ContrastTests`); theme colors are asset colors with light and dark variants (V.1); previews at accessibility5 and in Dark Mode; new audited states (contracts/screens.md); nothing animates. |
| VI. Privacy & Security | Pass | Three settings on the device; `UserDefaults` already declared (CA92.1); sound needs no permission and no required-reason API, so the privacy manifest does not change (R12). |
| VII. Performance | Pass | Measured first: settings read in 2.4 µs on the main actor; the sound files load (107 ms) and play calls run (11–69 ms on the Mac) in an actor, never on the main actor (VII.3); the iPhone's latency is checked by hand (quickstart §5). |
| VIII. Simplicity & Dependencies | Pass | No dependencies; a standard-library Python script instead of a sound pack; three keys instead of a versioned format; `AVAudioPlayer` before `AVAudioEngine` (R7). |
| IX. Observability | Pass | New `settings` and `sound` logging categories, without values (R12). |
| Workflow gates | Pass | spec → clarify → plan → tasks → implement; every new view has previews with in-memory settings and the recording player. |

**Gate result (pre-research)**: PASS. No violations.

### Dependency justification (Principle VIII)

| Dependency | Why Apple frameworks fall short | Maintenance | License | Added via |
|---|---|---|---|---|
| *(none added)* | | | | |

The sound script uses Python's standard library only and runs at development time and in CI's
script tests; nothing from it ships but the four WAV files it writes.

### Lint allow-list

| File | Rule | Reason |
|---|---|---|
| *(none)* | | The allow-list stays empty. |

### Audit allow-list

| Screen | Element | Issue type | Reason |
|---|---|---|---|
| Game setup | A static text line, or Start (`setup.start`), that the scrolling form cuts at the screen's edge | Dynamic Type, "partially unsupported" only | Unchanged from E4. |
| Setup and Home, while a system alert shows | A static text of the alert, or an element the audit does not name | Dynamic Type, "partially unsupported" only | Unchanged from E5. |

New screens add no entries; if the Settings form's system toggles or picker are reported, the
entry is added here with its reason, as for the setup form.

### Other recorded decisions

- **Spec alignment**: FR-021 asked for a board picture in every Rules section; the undo and resign
  section shows the game menu's two items instead (R9), and FR-021, US2's first scenario and
  SC-006 now say so.
- **Earlier requirements replaced**: E3's FR-003 (placeholders) by FR-001 and FR-020; E3's FR-028
  (hints always on) by FR-006. E3's `contracts/screens.md` keeps its history; this slice's screens
  contract records the removals.
- **Earlier tests that change** (R13): the placeholder tests (`placeholderMessages`, the
  placeholder UI tests, `testUS5_auditRules`, `testUS5_auditSettings`),
  `LocalizationTests.prototypeStringsRemoved` and `screenStrings`, `PaletteTests`,
  `US4ContrastTests`, `LoggingTests`; each is rewritten first, with the story that changes it.
- **Classic moves, unchanged**: its 12 colors move into the `Classic/` asset folder with their
  values, so E7's measurements stay valid.
- **The prototype stays deleted**: its designs are read from git history (`e3c0c2b^`) for the
  colors; nothing of it returns to the app.

### Post-design re-check

Re-evaluated after Phase 1 ([data-model.md](data-model.md),
[contracts/settings-and-sound.md](contracts/settings-and-sound.md),
[contracts/screens.md](contracts/screens.md), [contracts/rules-content.md](contracts/rules-content.md),
[quickstart.md](quickstart.md)): no violations. The design adds one observed settings object, two
injected seams with live and fake conformances, an actor for audio, one static board view shared
by previews and pictures, and engine-built Rules content; views stay thin, and nothing blocks the
main actor. **Gate result (post-design)**: PASS.

## Project Structure

### Documentation (this feature)

```text
specs/007-settings-themes-sound-and-rules/
├── plan.md                  # This file
├── research.md              # Phase 0 decisions R1–R13, with measurements
├── data-model.md            # App types
├── quickstart.md            # Validation scenarios
├── contracts/
│   ├── settings-and-sound.md  # Stored settings, hints, themes, sounds
│   ├── screens.md             # Settings, Rules, game board, audit
│   └── rules-content.md       # The seven sections, pictures and descriptions
├── checklists/
│   ├── requirements.md      # Spec quality checklist
│   └── validation.md        # Quickstart results (written during implementation)
└── tasks.md                 # Phase 2 output (/speckit-tasks)
```

### Source Code (repository root)

```text
scripts/
├── make-sounds.py                        # new: writes the four sounds; --check compares (R6)
└── tests/test-make-sounds.sh             # new: runs make-sounds.py --check in run.sh
checkers/checkers/
├── Features/Settings/
│   ├── BoardTheme.swift                  # new: classic, modern, playful; names
│   ├── SettingsStore.swift               # new: SettingsValues, protocol, UserDefaults and in-memory stores
│   ├── AppSettings.swift                 # new: @Observable settings, saved on change
│   └── SettingsView.swift                # new: theme picker with previews, two toggles
├── Features/Sound/
│   ├── SoundEffect.swift                 # new: the four effects, of(_:)
│   ├── SoundPlayer.swift                 # new: protocol, AudioSoundPlayer, RecordingSoundPlayer
│   ├── SoundBank.swift                   # new: actor with the audio session and players; SoundError
│   └── Sounds/                           # new: move, capture, crowning, gameEnd (.wav, generated)
├── Features/Rules/
│   ├── RulesContent.swift                # new: sections and engine-built pictures
│   └── RulesView.swift                   # new: one scrolling page
├── Features/Game/
│   ├── BoardPicture.swift                # new: static board or part of one, with marks
│   ├── BoardView.swift                   # theme from the environment
│   ├── PieceView.swift                   # theme from the environment
│   ├── GameSession.swift                 # settings and sounds; sound per step and on resign
│   └── GameSession+Display.swift         # hints off empties hintedPieces and targets
├── Features/Placeholders/                # deleted
├── Support/Palette.swift                 # color(in:); the boardTheme environment value
├── Support/Logging.swift                 # + settings, sound categories
├── App/AppRouter.swift                   # settings store and sound player; AppSettings to sessions
├── App/RootView.swift                    # Settings and Rules destinations; theme in the environment
├── CheckersApp.swift                     # live settings store and sound player
├── Assets.xcassets/                      # Classic/ (moved), Modern/, Playful/ (12 colors each)
└── Localizable.xcstrings                 # + Settings and Rules texts, theme names; − placeholder lines
checkers/checkersTests/
├── US1SettingsTests.swift                # store, fallback, AppSettings, hints on and off
├── US2RulesTests.swift                   # section order, pictures checked by the engine, word count
├── US3ThemeTests.swift                   # theme names and stored values; every theme resolves
├── US4SoundTests.swift                   # the sound per step and ending, sound off, files load
├── US4ContrastTests.swift                # changed: every theme
├── PaletteTests.swift                    # changed: every theme
├── LocalizationTests.swift               # changed: new strings; theme names allowed again
├── LoggingTests.swift                    # changed: two categories
└── US7NavigationTests.swift              # changed: placeholder test removed
checkers/checkersUITests/
├── Support/AppScreens.swift              # launch helper with settings arguments
├── US1SettingsUITests.swift              # from Home and the menu; hints kept after relaunch
├── US2RulesUITests.swift                 # from Home and the menu; back to the same game
├── US3ThemeUITests.swift                 # choose a theme; kept after relaunch
├── US7NavigationUITests.swift            # changed: no placeholders
└── US5AccessibilityAuditUITests.swift    # changed: Settings, Rules, themed boards
```

**Structure Decision**: Settings, Sound and Rules each get a feature folder (Constitution II.1).
The board drawing stays in the Game feature, which the Settings previews and the Rules pictures
reuse through `BoardPicture`; the rules of what hints and sounds do stay in `GameSession`, which
already owns every step.

## Complexity Tracking

No violations to justify.

## Follow-ups for other slices

- **E8 (#177)**: the no-network and no-permission check covers the sound playback too.
- **E8 (#182)**: the hitch check covers sound playback during the computer's chains.
- **If the iPhone check misses 0.1 s (SC-004)**: move `SoundBank` to `AVAudioEngine` player
  nodes (R7), measured first.
