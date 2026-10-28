# Store listing: Checkers 1.0

The texts of the App Store page and of TestFlight, in the fields of
`specs/008-release-1-0/contracts/store-listing.md`. Each `##` heading is one App Store Connect
field, and the text below it is pasted as it is, so each paragraph and list item is one line;
HTML comments are notes and are not pasted. `scripts/tests/test-store-listing.sh` checks
Apple's limits. The owner reviews every statement against `FRD.md` (each description paragraph
names its IDs) and approves the texts and the name before they are entered (T039, T040). This
file stays the source when a field changes.

## Name

Checkers – Classic Board Game
<!-- A proposal: the store name must be unique in the App Store, so App Store Connect decides.
If it is taken, the owner picks another and changes it here. The name under the icon stays
"Checkers" whatever this is (FR-016). -->

## Subtitle

American rules, fully offline

## Promotional text

Classic American checkers for one or two players. Three computer levels, automatic saving, statistics, three board themes and full VoiceOver support.

## Description

Play American checkers on your iPhone, against the computer or with a friend on the same phone. Checkers works fully offline: there is no account and no analytics, and your games, statistics and settings stay on your iPhone.
<!-- FR-SETUP-01, FR-PRIV-01, FR-PRIV-02; FRD §2 -->

Choose Easy, Medium or Hard. Easy is beatable by a beginner, and Hard is a challenge for experienced casual players. Play as Light, as Dark, or let the app pick a side at random. The computer shows when it is thinking, and it plays a chain of jumps one jump at a time so you can follow it.
<!-- FR-SETUP-02, FR-AI-02, FR-AI-03, FR-AI-05 -->

The standard American rules, on an 8×8 board: captures are mandatory, a piece keeps jumping while it can, and a man that reaches the far row is crowned king. A side with no legal move loses, and a game is drawn when a position comes back for the third time or after 40 moves each without a capture or a man moving.
<!-- FR-RULE-01 to FR-RULE-07, FR-END-01, FR-END-03, FR-END-04 -->

Move by tapping or by dragging a piece. Move hints show which pieces can move and where they can go, and you can turn them off. Undo takes back as many moves as you like, and the game menu lets you resign.
<!-- FR-MOVE-01, FR-MOVE-02, FR-AID-01, FR-AID-02, FR-AID-04, FR-SET-01, FR-UNDO-01, FR-END-02 -->

Your game is saved after every turn, so you can leave at any moment and continue later. Statistics keep your wins, losses and draws against each level.
<!-- FR-SAVE-01, FR-SAVE-03, FR-NAV-02, FR-STAT-01 -->

Pick one of three board themes, Classic, Modern or Playful, and turn sound effects on or off. Illustrated rules explain the game, from the first move to crowning, winning and draws.
<!-- FR-SET-01, FR-SET-02, FR-SND-01, FR-HELP-01 -->

Made for everyone: every square works with VoiceOver, so you can play a whole game square by square, with every move announced, including the computer's. Text grows to the largest sizes, Dark Mode is supported, and pieces, kings and hints never rely on color alone.
<!-- FR-A11Y-01 to FR-A11Y-05 -->

## Keywords

draughts,board game,strategy,classic,offline,two player,family,kings,jump,logic,brain,tabletop
<!-- No competitor or trademark names. "checkers" is left out because the name already carries it. -->

## Support URL

https://iglooo101.github.io/checkers/

## Privacy policy URL

https://iglooo101.github.io/checkers/privacy/

## Category

Primary category: Games, subcategory Board. No secondary category.

## Age rating

Every answer in the age rating questionnaire is None or No: no violence of any kind, no mature, suggestive, horror or medical themes, no profanity, no alcohol, tobacco or drugs, no gambling or simulated gambling, no contests, no unrestricted web access, no user-generated content, no messaging or chat, no advertising and no in-app purchases. The rating is 4+.

## Price and availability

Free (no in-app purchases), in every country and region. iPhone only: availability on Apple silicon Macs and on Apple Vision Pro is turned off.

## Copyright

2026 Hussein Helmy
<!-- The owner's name as it should appear: to be confirmed by the owner (T039). -->

## App Review notes

Checkers needs no account and no sign-in, works fully offline and has nothing to configure.

How to see each feature:
- Two-player game: New game › Two players › Start. Both sides play on this iPhone.
- Against the computer: New game › Computer, choose Easy, Medium or Hard and a side, then Start.
- Undo and Resign: the menu at the top right of the game screen.
- Continue: leave a game for Home (menu › Home); Home then offers Continue.
- Statistics: finish or resign a game against the computer, then open Statistics from Home.
- Rules and Settings: from Home, or from the game screen's menu. Settings has the board theme, sound effects and move hints.

The app collects no data, makes no network requests and asks for no permission.

## Privacy label

Data Not Collected. Everything the app keeps (the saved game, the record and the settings) is processed only on the device, and crash reports that players choose to share are collected by Apple, not by the app.
<!-- Research R13: "Data that is processed only on device is not 'collected' and does not need to
be disclosed"; "You are not responsible for disclosing data collected by Apple". -->

## What to Test

Thank you for testing Checkers.

Please play at least one game against the computer and one two-player game, and look through Rules and Settings (board themes, sound effects, move hints). Leave a game in the middle, close the app and come back: Continue should take you back to the same position.

If you are new to checkers, please play three games against Easy and tell us how it went: you should be able to win at least one.

To send feedback, take a screenshot in the app and share it with TestFlight, or open the TestFlight app, choose Checkers and tap Send Beta Feedback. Tell us what you did, what you expected and what happened.

## Version

1.0, released manually after App Review approves it.
