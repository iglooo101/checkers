// swift-tools-version: 6.2

import PackageDescription

// UI-free checkers logic (Constitution II). The macOS platform exists only so `swift test`
// runs on the development Mac; the app ships on iOS.
let package = Package(
    name: "CheckersEngine",
    platforms: [
        .iOS("26.2"),
        .macOS(.v15),
    ],
    products: [
        .library(name: "CheckersEngine", targets: ["CheckersEngine"])
    ],
    dependencies: [
        .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", exact: "0.65.1")
    ],
    targets: [
        .target(
            name: "CheckersEngine",
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")]
        ),
        .testTarget(
            name: "CheckersEngineTests",
            dependencies: ["CheckersEngine"],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")]
        ),
        // The computer's strength matches (specs/005-computer-opponent/research.md R6). They
        // need a Release build (`swift test -c release`), so they run in the CI job
        // engine-strength instead of the Xcode test plan.
        .testTarget(
            name: "CheckersEngineStrengthTests",
            dependencies: ["CheckersEngine"],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")]
        ),
    ]
)
