import CheckersEngine
import SwiftUI

/// The Classic board and piece colors, each an asset-catalog color with light and dark variants
/// (Constitution V.1). Views take board colors only from here; other themes arrive with E6.
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

    var color: Color {
        Color(rawValue)
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
