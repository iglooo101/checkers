# Validation: Accessibility

Results of the scenarios in [../quickstart.md](../quickstart.md), recorded during implementation
on the development Mac (Intel Core i9-9980HK, Xcode 26.3, iPhone 17 simulator on iOS 26.3),
starting 2026-10-22.

## Baseline (T001)

| Check | Result | Notes |
|---|---|---|
| `scripts/test.sh` before any slice code | Pass | 130 of 130 (E3's last code commit `e3c0c2b`, CI run 39708152757); no app code has changed since |
| Classic contrast against the dark square `#7a4a24` (research R5) | Measured | Light piece 7.1:1, dark piece 2.3:1, dark-piece outline 1.1:1, selection ring and target dot 1.5:1 (2.6:1 dark), hint ring 4.4:1; crown on a Light king 1.6:1; Light versus Dark pieces 16.1:1 |

## 1. All automated tests (SC-002 to SC-006)

*Pending (T023).*

## 2. One story at a time (US1–US5)

*Pending (T023).*

## 3. Play with VoiceOver (SC-001)

*Pending (T023).*

## 4. Without color (SC-005)

| Check | Result | Notes |
|---|---|---|
| Contrast of every mark (`US4ContrastTests`, T016–T017) | Pass | 3:1 or more for all 8 pairs in both appearances; the Classic colors are now the same in light and dark appearance |
| The board in grayscale on the simulator (T018) | Pass | Two-player game with c3 selected, screenshots in light and dark appearance converted to the Generic Gray profile (`simctl` has no Color Filters switch): Light and Dark pieces, the thick ring on the selected piece, the thin rings on the hinted pieces and the dots on the target squares are all told apart |
| Kings in grayscale (T018) | Pass | `PieceView` kings rendered offscreen and converted the same way: the dark crown on a Light king and the gold crown on a Dark king both stand out. The offscreen renderer leaves out the board's square cells, so kings on the board are checked in the new "Every mark" previews |

## 5. CI

*Pending (T026).*
