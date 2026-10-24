# Data Model: Settings, Themes, Sound and Rules

Types this feature adds or changes, all in the app target (the engine does not change). They
follow E3 to E5 (`specs/006-saving-and-statistics/data-model.md`). The app target's default
isolation is the main actor, so the value types that the nonisolated `Palette`, the `SoundBank`
actor or parameterized tests use are declared `nonisolated` and `Sendable`: `BoardTheme`,
`SettingsValues`, `SoundEffect` and `SoundError` (as `GameSetup`, `Record` and `Palette` are). Behavior is in
[contracts/settings-and-sound.md](contracts/settings-and-sound.md); screens in
[contracts/screens.md](contracts/screens.md); the Rules content in
[contracts/rules-content.md](contracts/rules-content.md).

## Settings (`Features/Settings/`)

### BoardTheme (new, R4)

| Case | Stored as | Name shown | Asset folder |
|---|---|---|---|
| `classic` | `"classic"` | Classic | `Classic/` |
| `modern` | `"modern"` | Modern | `Modern/` |
| `playful` | `"playful"` | Playful | `Playful/` |

A `String`-backed, `CaseIterable`, `nonisolated`, `Sendable` enum. Unknown stored names read as
unreadable (R1). `name` is a `LocalizedStringResource`, added with US3: the names are catalog
strings that E3's `prototypeStringsRemoved` forbids until US3 changes that test (research R13).

### SettingsValues (new, R1)

| Field | Type | Default | Key |
|---|---|---|---|
| `boardTheme` | `BoardTheme` | `.classic` | `boardTheme` (string) |
| `soundEffects` | `Bool` | `true` | `soundEffects` (boolean) |
| `moveHints` | `Bool` | `true` | `moveHints` (boolean) |

An `Equatable`, `nonisolated`, `Sendable` value type with `static let defaults` (FR-002).

### SettingsStore (new protocol, R1)

| Member | Meaning |
|---|---|
| `load() -> SettingsValues` | Each key on its own: missing gives its default; the wrong type or an unknown theme gives its default and is logged (FR-005). Never throws |
| `save(_ values: SettingsValues)` | Writes each key whose value changed |

Conformances: `UserDefaultsSettingsStore(defaults:)` (the app, `UserDefaults.standard`) and
`InMemorySettingsStore` (tests and previews; it can be given raw stored objects to test the
unreadable cases).

### AppSettings (new, `@Observable` class, R2)

| Member | Meaning |
|---|---|
| `boardTheme`, `soundEffects`, `moveHints` | The current values; setting one saves it through the store at once (FR-003, FR-004) |
| `init(store:)` | Loads the values; the router builds it, so it exists before the first frame |

A class, as shared mutable state that the router, every session and the Settings screen observe
(Constitution II.4).

## Sound (`Features/Sound/`)

### SoundEffect (new, R8)

| Case | File | Played when | Length (measured) |
|---|---|---|---|
| `move` | `move.wav` | A step that neither captures, crowns nor ends the game | 0.12 s |
| `capture` | `capture.wav` | A capturing step (each jump of a chain) that neither crowns nor ends the game | 0.22 s |
| `crowning` | `crowning.wav` | A crowning step that does not end the game | 0.45 s |
| `gameEnd` | `gameEnd.wav` | A step that ends the game, or a resignation | 1.2 s |

`static func of(_ result: StepResult) -> SoundEffect` picks by that order (game end, crowning,
capture, move). `nonisolated` and `Sendable`, since the `SoundBank` actor uses it.

### SoundPlayer (new protocol, R7)

| Member | Meaning |
|---|---|
| `play(_ effect: SoundEffect)` | Plays a sound and returns at once; never fails for the caller |
| `isAvailable: Bool` | Whether sounds can play: `true` at first and after a successful preparation or sound, `false` after a `SoundError` (FR-017, FR-SND-05); observed |

Conformances: `AudioSoundPlayer` (the app: an `@Observable` class that starts the bank's
preparation when created, hands each sound to the `SoundBank` actor, sets `isAvailable` from the
outcome, logs each `SoundError` under `Log.sound`, and tells the bank when the system resets its
media services) and `RecordingSoundPlayer` (tests and previews: keeps the effects in order, plays
nothing, and has a settable `isAvailable`, `true` by default).

### SoundBank (new actor, R7)

Owns the audio session's `.ambient` category and one prepared `AVAudioPlayer` per effect.

| Member | Meaning |
|---|---|
| `init(directory: URL)` | Where the four files are: the app bundle's resources in the app, a temporary directory in tests |
| `isPrepared: Bool` | Whether its four players are ready |
| `prepare() throws(SoundError)` | Sets the category and loads the four players; on failure the bank stays unprepared |
| `play(_ effect:) throws(SoundError)` | Prepares first if unprepared, then rewinds and plays one; a player that does not start throws `playback` and discards the players |
| `mediaServicesWereReset()` | Discards the players, so the next sound prepares new ones |

### SoundError (new, R7)

| Case | When |
|---|---|
| `missingFile(SoundEffect)` | The bundle has no file for the effect |
| `unreadableFile(SoundEffect)` | The file does not load as audio |
| `audioSession` | The session's category cannot be set |
| `playback(SoundEffect)` | A prepared player does not start |

`Equatable`, `nonisolated` and `Sendable`. What happens after each is in
[contracts/settings-and-sound.md](contracts/settings-and-sound.md), "When sounds cannot play".

## Game (changed)

### GameSession (changed, R2, R3, R8)

| Change | Meaning |
|---|---|
| `init(…, settings: AppSettings = …, sounds: any SoundPlayer = RecordingSoundPlayer())` | New parameters with in-memory defaults, so the 46 existing constructions stay as they are |
| `hintedPieces`, `targets` | Empty while `settings.moveHints` is off (FR-006) |
| `applyStep` | Plays `SoundEffect.of(result)` after the announcement while `settings.soundEffects` is on (FR-014) |
| `resign()` | Plays `gameEnd` when the resignation ends the game, while sound effects are on (FR-015) |

### Palette (changed, R5)

The 12 cases stay; `color` becomes `color(in theme: BoardTheme) -> Color`, reading
`"<Theme>/<Name>"` from the asset catalog. `crown(for:)` is unchanged.

### Environment value `boardTheme` (new, R2)

`EnvironmentValues.boardTheme: BoardTheme`, default `.classic`; `RootView` sets it from
`AppSettings`. `BoardView`, `PieceView` and `BoardPicture` read it.

## Boards and Rules (`Features/Rules/`, shared view in `Features/Game/`)

### BoardPicture (new view, R5)

| Input | Meaning |
|---|---|
| `position` | The pieces to draw |
| `rows`, `columns` | The part of the board to draw, from Light's side (default all eight) |
| `selected`, `hinted`, `targets` | The marks, drawn as on the game board |
| `description` | The VoiceOver label of the whole picture |

No input, no session; one accessibility element with the image trait.

### RulesSection and RulesPicture (new, R9)

| Type | Fields |
|---|---|
| `RulesSection` | `id` (for identifiers), `title`, `text` (localized), `pictures` |
| `RulesPicture` | `.board(state: GameState, selected: Square?, description:)`, whose marks come from the engine and are drawn as the game board draws them with hints on: with a selected piece, its selection ring, its targets (`targets(from:)`) as dots and the side to move's `movablePieces` as hint rings (the selected one shows its selection ring); with none, no marks. Or `.menu` (the Undo and Resign items) |

`RulesContent.sections` lists the seven sections of [contracts/rules-content.md](contracts/rules-content.md).

## App (changed)

| Type | Change |
|---|---|
| `AppRouter` | Takes a `SettingsStore` and a `SoundPlayer` (defaults: in-memory and recording); owns `settings: AppSettings`; passes both to every session it starts or continues; `showsSoundNotice` is `settings.soundEffects && !sounds.isAvailable` (FR-017) |
| `RootView` | Settings and Rules destinations replace the placeholders; sets `\.boardTheme` |
| `CheckersApp` | Passes `UserDefaultsSettingsStore(defaults: .standard)` and an `AudioSoundPlayer`, whose sound bank starts preparing after launch |
| `Log` | New categories `settings`, `sound` |
| `PlaceholderView`, `PlaceholderText` | Deleted |
