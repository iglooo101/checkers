# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

An iOS (SwiftUI, deployment target iOS 26.2) checkers app. Almost all of the game and visuals live in bundled HTML/CSS/JS files; the Swift side is a thin shell that displays them in a `WKWebView`. Single target/scheme `checkers`, no test target, no third-party dependencies. The git repository root is the parent directory (remote: `github.com/iglooo101/checkers`).

## Build & run

```sh
# Build for the simulator (run from this directory)
xcodebuild -project checkers.xcodeproj -scheme checkers -destination 'generic/platform=iOS Simulator' build
```

To iterate on a screen without rebuilding the app, open the HTML file directly in a browser (e.g. `open checkers/Play.html`) — each page is self-contained and also works outside the web view.

## Architecture

- `checkers/ContentView.swift` — a segmented `Picker` over a hardcoded `screens` list of `(title, file)` pairs, and a `WebView` (`UIViewRepresentable`) that loads `<file>.html` from the main bundle via `loadFileURL(_:allowingReadAccessTo:)` with read access to the bundle directory (so pages can reference sibling resources such as `move.wav`). `.id(selected)` forces a fresh `WKWebView` on every tab switch, so page state (e.g. an in-progress game) is not preserved across tabs.
- The Xcode project uses **file-system synchronized groups** (`objectVersion = 77`): any file dropped into `checkers/` is automatically part of the target — no `project.pbxproj` edits needed to add HTML/Swift/audio files. To add a new screen, add the `.html` file and an entry to `screens` in `ContentView.swift`.
- HTML screens:
  - `Classic.html`, `Modern.html`, `Playful.html` — static, non-interactive board mockups in different visual styles, authored at a fixed 640×640 and scaled to the viewport by a `fitBoard()` script using CSS `zoom`.
  - `Play.html` — the playable game. Vanilla JS, two-player hot-seat (Light `'w'` moves first, upward; Dark `'b'`). Board is an 8×8 array of `{color, king}` or `null`. `legalMoves()` generates all moves for a color, with `captureChains()` recursively enumerating multi-jump captures; captures are mandatory (if any exist, only captures are returned). A move is `{path: [[r,c],...], caps: [[r,c],...]}`. Kinging happens on reaching the far row and ends the move. A player with no legal moves loses. Board sizing is responsive via the `--cell` CSS variable. Plays `move.wav` on each move.

## Leftovers to be aware of

- `checkers/Item.swift` is the unused SwiftData `@Model` from the Xcode template; nothing references it.
- `checkers/Assets.xcassets/CheckersApp.swift` is a stray duplicate of `checkers/CheckersApp.swift` inside the asset catalog. Edit the one at `checkers/CheckersApp.swift`.
