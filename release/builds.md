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
