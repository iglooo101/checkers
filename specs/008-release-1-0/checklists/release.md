# Release checklist: Checkers 1.0

Every hand check left open by E3 to E7 and E8's own device checks (spec FR-026, research R16), run
on TestFlight builds. For each row, fill in the build it was run on (a number from
`release/builds.md`), the result (`passed`, `failed` or `accepted`) and, for an accepted item,
the owner's reason in their own words. `scripts/release.sh submit-check <build>` allows the
submission only when every row is passed or accepted on that build, or on an earlier build whose
later builds' notes in `release/builds.md` say they cannot affect it ("cannot affect RC-04");
a failed item is fixed through FR-027 and run again on the new build. The FRD IDs in each row feed
the manual-checks column of `../traceability.md` (`scripts/traceability.py`).

| ID | Source | Check | Build | Result | Reason |
|---|---|---|---|---|---|
| RC-01 | E3 `validation.md` §3 | A full two-player game by hand from Home to the result panel, by taps and drags, with a capture chain, a crowning, undo, a resignation and Play again (E3 quickstart §3). FR-MOVE-01 FR-MOVE-02 FR-CHAIN-01 FR-RULE-07 FR-UNDO-01 FR-END-02 FR-END-06 FR-END-07 | | | |
| RC-02 | E3 `validation.md` §4 | At the largest accessibility text size, in light and in dark: Home, setup, a game and its result panel look right, with nothing cut off or overlapping. FR-A11Y-04 | | | |
| RC-03 | E7 `validation.md` §3 | A game with VoiceOver on, square by square (E7 quickstart §3): each square's label, double-tap to select and to move, a chain one jump at a time, each move and the result announced once, focus following each move. FR-A11Y-01 FR-A11Y-02 FR-A11Y-03 | | | |
| RC-04 | E4 `validation.md` §4 | Playtest: a tester new to checkers plays three games against Easy and wins at least one. FR-AI-02 | | | |
| RC-05 | E4 `validation.md` §4 | Playtest: an experienced casual player plays three games against Hard at their best and finds it a challenge. FR-AI-02 | | | |
| RC-06 | E4 `validation.md` §3 | Home from the game menu while the computer thinks, then Continue: the position is the same and the computer makes exactly one move. FR-NAV-03 FR-AI-04 FR-SAVE-04 | | | |
| RC-07 | E4 `validation.md` §6 | VoiceOver against the computer: each of its moves is announced once, a chain without "Jump again.", and focus stays where it was. FR-A11Y-03 | | | |
| RC-08 | E5 `validation.md` §2 | Close the app from the app switcher in the middle of a game, open it again: Continue restores the same position. FR-SAVE-01 FR-SAVE-03 | | | |
| RC-09 | E5 `validation.md` §2 | Go to the Home Screen while the computer thinks, open the app again and Continue: the computer moves exactly once. FR-SAVE-01 FR-SAVE-04 | | | |
| RC-10 | E5 `validation.md` §4 | Finish a game by hand at Easy and one at Medium: Statistics counts each once, at its level. FR-STAT-01 FR-STAT-02 | | | |
| RC-11 | E5 `validation.md` §6 | VoiceOver reads each Statistics level as one sentence. FR-STAT-01 FR-A11Y-04 | | | |
| RC-12 | E6 `validation.md` §5 | Each sound starts within 0.1 s of its step: `scripts/device.sh session` (RC-23) and by ear. FR-SND-01 | | | |
| RC-13 | E6 `validation.md` §5 | With the phone on silent, the game plays no sound. FR-SND-02 | | | |
| RC-14 | E6 `validation.md` §5 | The volume buttons change the sounds' volume. FR-SND-02 | | | |
| RC-15 | E6 `validation.md` §5 | Music from another app keeps playing under the game's sounds. FR-SND-02 | | | |
| RC-16 | E6 `validation.md` §5 | A second sound starts over the first (a capture right after a move sound). FR-SND-01 | | | |
| RC-17 | E6 `validation.md` §3 | VoiceOver through Rules: each section's title is read as a heading and the rotor moves between them. FR-HELP-01 FR-A11Y-04 | | | |
| RC-18 | E6 `validation.md` §5 | VoiceOver in Settings: each theme row is read as its name, the chosen one as selected, and nothing for the small boards or the checkmark. FR-SET-02 FR-A11Y-04 | | | |
| RC-19 | E8 T012 (FR-001 to FR-003) | A fresh install with Settings › Privacy & Security › App Privacy Report on: every screen, both kinds of game, the phone turned sideways; the report shows no network activity, no permission is asked, nothing asks for an account, and the app stays in portrait. FR-PRIV-01 FR-PRIV-02 FR-PLAT-01 | | | |
| RC-20 | E8 T013 (FR-004) | The build's archive in Xcode's Organizer, Generate Privacy Report: no tracking, no collected data, user defaults (CA92.1) only. FR-PRIV-01 | | | |
| RC-21 | E8 T014 (FR-005) | The build's app on the "iPad (A16) E8" simulator: it opens in iPhone compatibility mode, in portrait, and a game can be played. FR-PLAT-01 | | | |
| RC-22 | E8 T021 (FR-011) | `scripts/device.sh launch` on the build's commit: the median of ten cold launches is under 0.4 s. FR-NAV-01 | | | |
| RC-23 | E8 T021 (FR-012, FR-013) | `scripts/device.sh session` on the build's commit: hitch-time ratio under 5 ms/s and total under 0.25 s; the computer's first step 0.5–1.0 s after its turn starts in at least 95% of turns and never over 1.5 s; each sound's start plus the output latency within 0.1 s. FR-AI-03 FR-AI-04 FR-SND-01 | | | |
| RC-24 | E8 T028 (FR-008, FR-009) | While Xcode debugs the build's commit on the phone, Debug › Simulate MetricKit Payloads: one `diagnostics` log line per kind, with its times. | | | |
| RC-25 | E8 T034 (FR-015 to FR-017) | The icon on the Home Screen in light, dark and tinted (Home Screen › Edit › Customize); the name under it reads "Checkers"; launching in light and in dark shows a plain screen, then Home, without a flash. FR-NAV-01 | | | |
| RC-26 | E8 FR-025 | The TestFlight install behaves as the local Release build: RC-19's walk-through, briefly, on the TestFlight build. FR-PRIV-01 FR-PLAT-01 | | | |
| RC-27 | E8 FR-025 | External testers: Beta App Review passed, the testers were invited with What to Test, the feedback window of at least a week has closed, and every report was answered (FR-027). | | | |

## Rejections (FR-029)

Each App Review round's reason and answer, newest last.

| Build | Date | Reason | Answer |
|---|---|---|---|
