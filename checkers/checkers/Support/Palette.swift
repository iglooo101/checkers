import CheckersEngine
import SwiftUI

/// The board and piece colors, each an asset-catalog color with light and dark variants, in one
/// namespaced folder per board theme (Constitution V.1; specs/007-settings-themes-sound-and-rules/
/// research.md R4). Views take board colors only from here.
nonisolated enum Palette: String, CaseIterable {
    case boardLightSquare = "BoardLightSquare"
    case boardDarkSquare = "BoardDarkSquare"
    case boardFrame = "BoardFrame"
    case pieceLight = "PieceLight"
    case pieceLightEdge = "PieceLightEdge"
    case pieceDark = "PieceDark"
    case pieceDarkEdge = "PieceDarkEdge"
    case crownOnLight = "CrownOnLight"
    case crownOnDark = "CrownOnDark"
    case selection = "Selection"
    case hint = "Hint"
    case target = "Target"

    /// This color's asset in a theme's folder, such as "Modern/BoardDarkSquare".
    func assetName(in theme: BoardTheme) -> String {
        "\(theme.assetFolder)/\(rawValue)"
    }

    /// This color in a theme, with its light and dark variants (FR-GAME-07).
    func color(in theme: BoardTheme) -> Color {
        Color(assetName(in: theme))
    }

    /// The crown of a side's king, dark on Light kings and gold on Dark ones, so it stands out
    /// (specs/004-accessibility research R5).
    static func crown(for side: Side) -> Palette {
        switch side {
        case .light: .crownOnLight
        case .dark: .crownOnDark
        }
    }
}

extension BoardTheme {
    /// The asset-catalog folder that holds the theme's 12 colors.
    nonisolated var assetFolder: String {
        switch self {
        case .classic: "Classic"
        case .modern: "Modern"
        case .playful: "Playful"
        }
    }
}

extension EnvironmentValues {
    /// The theme every board drawing uses; `RootView` sets it from the settings, so a board is in
    /// the chosen theme from its first frame (FR-009).
    @Entry var boardTheme: BoardTheme = .classic
}
