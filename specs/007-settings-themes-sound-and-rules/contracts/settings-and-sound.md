# Contract: settings, themes and sound

Behavior of the settings, the board themes and the sound effects. Types are in
[../data-model.md](../data-model.md); screens and texts in [screens.md](screens.md).

## Stored settings (FR-002, FR-004, FR-005; research R1)

Three keys in `UserDefaults.standard`, each read and written on its own:

| Key | Value | Default | Read as unreadable (default used, logged) |
|---|---|---|---|
| `boardTheme` | `"classic"`, `"modern"` or `"playful"` | `"classic"` | Any other string, or a value that is not a string |
| `soundEffects` | boolean | `true` | A value that is not a boolean |
| `moveHints` | boolean | `true` | A value that is not a boolean |

- A missing key reads as its default and is not logged (first use).
- An unreadable value is logged under `Log.settings`, without the value; it is not rewritten
  until the player changes that setting. No alert (FR-005, Clarifications).
- Settings are not part of the saved game or the record, and do not change the setup choices.
- For one launch, UI tests set values with `-boardTheme modern`, `-soundEffects <false/>`,
  `-moveHints <true/>` (research R10).

## Applying a change (FR-003)

- `AppSettings` is the one source: a change is visible to every observer at once and saved before
  the setter returns.
- The board redraws in the new theme and with or without hints as soon as the game screen is
  shown again; the position, selection, chain, undo history and the computer's pending turn are
  untouched. While Settings or Rules covers the game, the computer's next step waits (E4,
  unchanged).

## Move hints (FR-006, FR-007; research R3)

| | Hints on | Hints off |
|---|---|---|
| `hintedPieces` | Movable pieces of the side to move (only capturing ones when a capture is required); none during the computer's turn or after the game | Empty |
| `targets` | The selected piece's legal targets | Empty |
| Selected piece's mark | Shown | Shown |
| Chain lock, drags and drops | As E3 | As E3 |
| "A capture is required." notice, turn text | As E3 | As E3 |
| VoiceOver square states | Always given (E7) | Always given (E7) |

## Themes (FR-008 to FR-012; research R4, R5)

- Asset colors `Classic/<Name>`, `Modern/<Name>`, `Playful/<Name>` for the 12 `Palette` names,
  each with light and dark variants; the colors are research R4's table.
- In every theme and appearance, each `US4ContrastTests` pair has at least 3:1 contrast, the
  target blended at its alpha over the dark square.
- Shapes do not change with the theme: the thin hint ring, the thick selection ring, the target
  dot and the side-specific crown (E7).
- Only the board is themed: squares, frame, pieces, crowns and marks, in the game, the Settings
  previews and the Rules pictures. Everything else keeps the app's colors.
- The theme is in the environment (`\.boardTheme`) from the first frame, so a continued game
  never shows Classic first.

## Sounds (FR-014 to FR-019; research R6 to R8)

### Which sound

| Event | Sound (sound effects on) |
|---|---|
| A step that ends the game (either side) | `gameEnd` |
| A step that crowns, game going on | `crowning` |
| A capturing step (each jump), no crowning, game going on | `capture` |
| Any other step | `move` |
| A resignation that ends the game | `gameEnd` |
| Undo, selecting, a refused tap or drop, the capture-required notice, Continue, opening or leaving a screen, the computer's thinking | none |

- One sound per step, played by `GameSession` in `applyStep` right after the announcement, for the
  player's steps and the computer's (paced, so each jump of its chain has its own sound as it
  appears). With sound effects off, nothing is played.
- A new sound starts even while the previous one plays (one player per sound; the same sound
  restarts from its beginning).

### Playback

- Audio session category `.ambient`: muted by the silent switch, follows the media volume, mixes
  with other apps' audio (FR-016). No permission, no background audio (FR-024).
- `SoundBank` (an actor) sets the category and loads the four prepared players on its first
  `prepare()`, started right after launch; `play` before that waits for the preparation.
  Nothing about sound runs on the main actor except handing over the effect.
- A `SoundError` (missing or unreadable file, session failure) is logged under `Log.sound`; the
  game continues, without that sound. Unit tests check that all four files are in the bundle and
  load, so these errors can only come from a broken build.

### Files (FR-019; research R6)

| File | Recipe | Length | Peak |
|---|---|---|---|
| `move.wav` | Wooden click: noise burst through resonators at 620 and 1,700 Hz, low thump | 0.12 s | −3 dBFS |
| `capture.wav` | Two sharper clicks (900/2,300 Hz, then 1,100/2,800 Hz), 70 ms apart | 0.22 s | −3 dBFS |
| `crowning.wav` | Chime: C6, then G6 60 ms later, bell partials | 0.45 s | −6 dBFS |
| `gameEnd.wav` | Rising phrase: G5, C6, E6, 180 ms apart | 1.2 s | −6 dBFS |

All 16-bit mono WAV at 44.1 kHz with an 8 ms fade-out, in `checkers/checkers/Features/Sound/Sounds/`,
generated by `scripts/make-sounds.py` with a fixed seed.

Recipe details (research R6's prototype, which produced the measured lengths and peaks):

| Building block | Definition |
|---|---|
| Random source | `random.Random(20261023)`, one generator for all sounds, used in the order move, capture (first click, second click) |
| Click (`low`, `high`, 0.12 s) | Noise burst `uniform(-1, 1) · exp(−t / 2 ms)`; through a two-pole resonator at `low` (pole radius 0.995) and one at `high` (0.990), each normalized to peak 1; plus a 180 Hz sine with `exp(−t / 18 ms)`; mixed 0.6 · low + 0.35 · high + 0.4 · thump |
| Two-pole resonator | `y[n] = x[n] + 2r·cos(2πf/44100)·y[n−1] − r²·y[n−2]` |
| Bell (`f`, length, `decay`) | Partials `f·m` with amplitude `a`, each `exp(−t·m / decay)`: (m, a) = (1, 1), (2, 0.35), (3.01, 0.15), (4.2, 0.08); linear 4 ms attack |
| move | Click(620, 1,700) |
| capture | Click(900, 2,300) at 0 s plus Click(1,100, 2,800) at 0.07 s, 0.22 s long |
| crowning | Bell(1,046.5, 0.45 s, 0.16) at 0 s plus Bell(1,568, 0.39 s, 0.14) at 0.06 s |
| gameEnd | Bell(784, 0.6 s, 0.25) at 0 s, Bell(1,046.5, 0.6 s, 0.25) at 0.18 s, Bell(1,318.5, 0.84 s, 0.32) at 0.36 s, 1.2 s long |
| Finish | Scale to the peak level, then fade linearly to zero over the last 8 ms; samples rounded to 16 bits and clamped to ±32,767 | `scripts/make-sounds.py --check` fails
when a committed file differs from its recipe by more than one sample step; `scripts/tests/run.sh`
runs it. To change a sound: change its recipe, run the script, listen, commit the files.
