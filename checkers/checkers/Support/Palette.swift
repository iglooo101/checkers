import SwiftUI

/// The Classic board and piece colors, each an asset-catalog color with light and dark variants
/// (Constitution V.1). Views take board colors only from here; other themes arrive with E6.
enum Palette: String, CaseIterable {
    case boardLightSquare = "BoardLightSquare"
    case boardDarkSquare = "BoardDarkSquare"
    case boardFrame = "BoardFrame"
    case pieceLight = "PieceLight"
    case pieceLightEdge = "PieceLightEdge"
    case pieceDark = "PieceDark"
    case pieceDarkEdge = "PieceDarkEdge"
    case crown = "Crown"
    case selection = "Selection"
    case hint = "Hint"
    case target = "Target"

    var color: Color {
        Color(rawValue)
    }
}
