import Foundation
import SwiftUI
import Testing
import UIKit

@testable import checkers

/// Board themes (specs/007-settings-themes-sound-and-rules/spec.md, US3; research R4).
struct US3ThemeTests {
    /// A theme's color in light and dark appearance, as "#RRGGBB" with the alpha when it is not 1.
    typealias Pinned = (light: String, dark: String)

    /// Every board color of every theme: Classic's as E7 measured them, Modern's and Playful's
    /// from research R4. A change here is a change the user approved (T021).
    static let pinned: [BoardTheme: [Palette: Pinned]] = [
        .classic: [
            .boardLightSquare: ("#F1DFB9", "#F1DFB9"), .boardDarkSquare: ("#7A4A24", "#7A4A24"),
            .boardFrame: ("#3B2415", "#3B2415"), .pieceLight: ("#FFFAF0", "#FFFAF0"),
            .pieceLightEdge: ("#A88F5F", "#A88F5F"), .pieceDark: ("#2A1A0E", "#2A1A0E"),
            .pieceDarkEdge: ("#D9B48A", "#D9B48A"), .crownOnLight: ("#6B4426", "#6B4426"),
            .crownOnDark: ("#E8C46A", "#E8C46A"), .selection: ("#7FD3FF", "#7FD3FF"),
            .hint: ("#E8C46A", "#F0D27A"), .target: ("#7FD3FF@0.85", "#7FD3FF@0.85"),
        ],
        .modern: [
            .boardLightSquare: ("#FFFFFF", "#D6D6D6"), .boardDarkSquare: ("#1C1C1C", "#1C1C1C"),
            .boardFrame: ("#111111", "#111111"), .pieceLight: ("#FFFFFF", "#F2F2F2"),
            .pieceLightEdge: ("#8E8E8E", "#8E8E8E"), .pieceDark: ("#0A0A0A", "#0A0A0A"),
            .pieceDarkEdge: ("#9A9A9A", "#9A9A9A"), .crownOnLight: ("#111111", "#111111"),
            .crownOnDark: ("#FFFFFF", "#FFFFFF"), .selection: ("#3FA9F5", "#3FA9F5"),
            .hint: ("#BDBDBD", "#BDBDBD"), .target: ("#3FA9F5@0.90", "#3FA9F5@0.90"),
        ],
        .playful: [
            .boardLightSquare: ("#FFF3D6", "#F2E3C2"), .boardDarkSquare: ("#1A639C", "#17598C"),
            .boardFrame: ("#2D1B4E", "#2D1B4E"), .pieceLight: ("#FFD60A", "#FFD60A"),
            .pieceLightEdge: ("#B38600", "#B38600"), .pieceDark: ("#C2185B", "#C2185B"),
            .pieceDarkEdge: ("#FFC2D1", "#FFC2D1"), .crownOnLight: ("#2D1B4E", "#2D1B4E"),
            .crownOnDark: ("#FFF3A1", "#FFF3A1"), .selection: ("#FFFFFF", "#FFFFFF"),
            .hint: ("#B8F03C", "#B8F03C"), .target: ("#FFFFFF@0.90", "#FFFFFF@0.90"),
        ],
    ]

    /// An asset color in an appearance, written as in `pinned`.
    static func written(_ color: Palette, in theme: BoardTheme, _ style: UIUserInterfaceStyle)
        throws -> String
    {
        let traits = UITraitCollection(userInterfaceStyle: style)
        let components = try US4ContrastTests.components(color, in: theme, traits)
        let hex = components.prefix(3).map { String(format: "%02X", Int(($0 * 255).rounded())) }
        let alpha = components[3] < 1 ? String(format: "@%.2f", components[3]) : ""
        return "#" + hex.joined() + alpha
    }

    @Test(
        "US3 FR-SET-02: the themes are named Classic, Modern and Playful, each with its own colors")
    func names() {
        #expect(BoardTheme.allCases.map(\.name.key) == ["Classic", "Modern", "Playful"])
        #expect(Palette.boardDarkSquare.assetName(in: .modern) == "Modern/BoardDarkSquare")
        #expect(Palette.hint.assetName(in: .classic) == "Classic/Hint")
    }

    @Test(
        "US3 FR-GAME-07 FR-SET-02: every theme's colors are the approved ones, in light and dark",
        arguments: BoardTheme.allCases)
    func approvedColors(theme: BoardTheme) throws {
        let colors = try #require(Self.pinned[theme])
        #expect(Set(colors.keys) == Set(Palette.allCases))
        for (color, expected) in colors {
            #expect(try Self.written(color, in: theme, .light) == expected.light, "\(color)")
            #expect(try Self.written(color, in: theme, .dark) == expected.dark, "\(color) dark")
        }
    }

    @Test("US3 FR-GAME-07: the board is drawn in Classic unless the environment says otherwise")
    func environmentDefault() {
        #expect(EnvironmentValues().boardTheme == .classic)
    }
}
