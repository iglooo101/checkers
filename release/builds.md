# Builds

Every build uploaded to App Store Connect, in order (specs/008-release-1-0/contracts/
release-tooling.md, "`release/builds.md`"). `scripts/release.sh` adds and moves the rows; a build
number is never reused, and a state only moves forward. The notes say what changed since the
previous build and which release checklist items it cannot affect ("cannot affect RC-04, RC-07").

| Build | Commit | Uploaded | State | Notes |
|---|---|---|---|---|
| 1 | 363f98ea615949efc73c7fea0e946b9a7cc2068f | 2026-10-29 | processed |  |
| 2 | 5e23e82b96f75a6f5d91296c9684030b1da4c0a7 | 2026-11-02 | processed | `Start` pinned below the form in Game setup (FR-SETUP-07, #216); cannot affect RC-20 |
| 3 | 718afe04cbe193b0e208438b1683630b15505074 | 2026-11-04 | processed | Difficulty and Side as one-line segmented controls in Game setup, so every choice and `Start` fit without scrolling (FR-SETUP-08, #217); cannot affect RC-20 |
| 4 | abfa729e6492ed2ea449f9ca3f9bde1145b85da5 | 2026-11-05 | processed | The three themes side by side in Settings, so every control and the Move hints explanation fit without scrolling (FR-SET-05, #218); cannot affect RC-20 |
| 5 | dbae342e3d531b0a6d1c5a530ef837c33cf00922 | 2026-11-05 | external | Every level easier: Easy, Medium and Hard look 1, 2 and 3 turns ahead, and Easy now and then gives a man away (FR-AI-02, #219); an engine-only change, so it cannot affect RC-01, RC-02, RC-03, RC-08, RC-11, RC-12, RC-13, RC-14, RC-15, RC-16, RC-17, RC-18, RC-19, RC-20, RC-22, RC-24, RC-25 |
