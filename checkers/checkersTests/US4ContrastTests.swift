import CheckersEngine
import Foundation
import Testing
import UIKit

@testable import checkers

struct US4ContrastTests {
    /// A mark and what it is drawn on, which must differ by at least 3:1 (WCAG non-text contrast).
    nonisolated struct Pair: CustomTestStringConvertible, Sendable {
        let mark: Palette
        let background: Palette
        var testDescription: String { "\(mark.rawValue) on \(background.rawValue)" }
    }

    nonisolated static let pairs = [
        Pair(mark: .pieceLight, background: .pieceDark),
        Pair(mark: .pieceLight, background: .boardDarkSquare),
        Pair(mark: .pieceDarkEdge, background: .boardDarkSquare),
        Pair(mark: .selection, background: .boardDarkSquare),
        Pair(mark: .target, background: .boardDarkSquare),
        Pair(mark: .hint, background: .boardDarkSquare),
        Pair(mark: .crownOnLight, background: .pieceLight),
        Pair(mark: .crownOnDark, background: .pieceDark),
    ]

    /// A theme in one appearance (specs/007-settings-themes-sound-and-rules/research.md R4).
    nonisolated struct Look: CustomTestStringConvertible, Sendable {
        let theme: BoardTheme
        let style: UIUserInterfaceStyle
        var testDescription: String { "\(theme.rawValue), \(style == .light ? "light" : "dark")" }
    }

    nonisolated static let looks = BoardTheme.allCases.flatMap { theme in
        [UIUserInterfaceStyle.light, .dark].map { Look(theme: theme, style: $0) }
    }

    @Test(
        "US4 FR-A11Y-05 FR-SET-02: every piece and mark has 3:1 contrast with what it is on, in every theme",
        arguments: pairs, looks)
    func contrast(pair: Pair, look: Look) throws {
        let traits = UITraitCollection(userInterfaceStyle: look.style)
        let background = try Self.components(pair.background, in: look.theme, traits)
        let mark = Self.blend(
            try Self.components(pair.mark, in: look.theme, traits), over: background)
        let ratio = Self.contrastRatio(mark, background)
        #expect(ratio >= 3, "\(pair.testDescription): \(ratio) in \(look.testDescription)")
    }

    @Test("US4 FR-A11Y-05: each side's king has its own crown color")
    func crownBySide() {
        #expect(Palette.crown(for: .light) == .crownOnLight)
        #expect(Palette.crown(for: .dark) == .crownOnDark)
    }

    /// sRGB components and alpha of a theme's asset color in the given appearance.
    static func components(_ color: Palette, in theme: BoardTheme, _ traits: UITraitCollection)
        throws -> [Double]
    {
        let named = try #require(
            UIColor(named: color.assetName(in: theme), in: .main, compatibleWith: traits))
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        named.resolvedColor(with: traits).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return [red, green, blue, alpha].map(Double.init)
    }

    /// A partly transparent color as it shows over an opaque background.
    static func blend(_ color: [Double], over background: [Double]) -> [Double] {
        let alpha = color[3]
        return (0..<3).map { alpha * color[$0] + (1 - alpha) * background[$0] } + [1]
    }

    /// WCAG contrast ratio of two opaque colors.
    static func contrastRatio(_ first: [Double], _ second: [Double]) -> Double {
        func luminance(_ rgb: [Double]) -> Double {
            let linear = rgb.prefix(3).map {
                $0 <= 0.039_28 ? $0 / 12.92 : pow(($0 + 0.055) / 1.055, 2.4)
            }
            return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]
        }
        let (lighter, darker) = (
            max(luminance(first), luminance(second)), min(luminance(first), luminance(second))
        )
        return (lighter + 0.05) / (darker + 0.05)
    }
}
