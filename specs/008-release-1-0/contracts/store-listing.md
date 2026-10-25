# Contract: Store listing, screenshots and public pages

Implements spec FR-016, FR-018 to FR-022 and US4 (research R11 to R13). The texts themselves are
written in `release/store-listing.md` during implementation and approved by the owner; this
contract fixes their fields, limits and sources.

## `release/store-listing.md`

| Field | Limit (checked by `test-store-listing.sh`) | Content rule |
|---|---|---|
| Name | 2–30 characters | Proposed by the owner and confirmed when App Store Connect accepts it; if taken, the owner picks another (spec edge case). Never changes the Home Screen name, "Checkers" (FR-016) |
| Subtitle | ≤ 30 characters | What the app is, e.g. classic American checkers, offline |
| Promotional text | ≤ 170 characters | Optional; plain |
| Description | ≤ 4,000 characters | Only what FRD v1.3 specifies; each paragraph ends with an HTML comment naming its FRD IDs, removed when pasted; no claims about other devices, languages or online play (FRD §19) |
| Keywords | ≤ 100 bytes, comma-separated, each over two characters | No competitor or trademark names |
| Support URL | full `https://` URL | `https://iglooo101.github.io/checkers/` |
| Privacy policy URL | full `https://` URL | `https://iglooo101.github.io/checkers/privacy/` |
| Category | — | Primary Games, subcategory Board |
| Age rating | — | Every questionnaire answer "None" or "No" (no violence, gambling, user content, web access, ads or purchases), giving 4+ |
| Price and availability | — | Free, every country and region; iPhone only: availability on Apple silicon Macs and on Apple Vision Pro turned off |
| Copyright | "YYYY Owner" | Year and the owner's name as the owner gives it |
| App Review notes | ≤ 4,000 bytes | No account or sign-in; works offline; nothing to configure; how to see each feature (two-player game, the three difficulties, Rules, Settings) |
| Privacy label | — | "Data Not Collected" (FR-020), consistent with R13's quotes |
| What to Test (TestFlight) | ≤ 4,000 characters | For the external testers (FR-025): play both kinds of game, try Rules and Settings; the tester new to checkers plays three games against Easy (E4 playtest: at least one win); how to send feedback from TestFlight |
| Version | — | 1.0, released manually after approval (FR-028) |

The owner enters these in App Store Connect; the file stays the source when a field changes.

## Screenshots (FR-019, R12)

Six portrait screenshots, 1206 × 2622 px RGB PNG, light appearance, default settings (Classic
theme, hints on, sound irrelevant), status bar 9:41 with full battery and signal:

| File | Screen | State |
|---|---|---|
| `01-home.png` | Home | a saved game, so Continue shows |
| `02-computer-game.png` | Game against the computer (Medium) | a few turns in, Light to move, hints on its movable pieces |
| `03-capture-chain.png` | Game | a selected piece in a capture chain, its next target marked |
| `04-king.png` | Game | a crowned king on the board after a crowning move |
| `05-rules.png` | Rules | the top of the page |
| `06-statistics.png` | Statistics | a record with games at each difficulty |

States come from `-savedGame` and `-record` launch arguments (E5), or from moves the test plays
in a two-player game, so every image is a real screen of the app. Every state that involves the
computer comes from `-savedGame` with the player to move: the computer draws each turn with a
fresh random seed, so a game played against it would differ between runs (FR-019). The owner approves them (or asks for other states)
before the first submission.

## Public pages (FR-021, R13)

GitHub Pages from `main`, folder `/docs`, Jekyll defaults (no `_config.yml`):

| File | URL | Says |
|---|---|---|
| `docs/index.md` | `https://iglooo101.github.io/checkers/` | What the app is; how to get help: open an issue at `github.com/iglooo101/checkers/issues` (a GitHub account is needed; no email is published); the privacy policy link |
| `docs/privacy.md` (front matter `permalink: /privacy/`) | `https://iglooo101.github.io/checkers/privacy/` | Checkers collects no data; it uses no network connection; it asks for no permission; the saved game, the record and the settings stay on the device and go with the app when it is deleted; crash reports that players choose to share with developers are collected by Apple under Apple's policy, not by the app; the date of the policy |

Both pages are Markdown, so pushing them runs no build (FR-021 and the repository's CI rule). A
check after Pages is enabled: both URLs answer 200 and contain their key sentence (quickstart
§4).

## Info.plist values (FR-016, FR-022, R11)

| Key | Value |
|---|---|
| `CFBundleDisplayName` | Checkers (from `InfoPlist.xcstrings`, English) |
| `ITSAppUsesNonExemptEncryption` | NO |
| `CFBundleShortVersionString` | 1.0 |
| `CFBundleVersion` | the build number from `release.sh archive` |
