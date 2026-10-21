import CheckersEngine
import SwiftUI

/// A man or a king on its square. A king carries a crown, so kings differ from men by shape, not
/// only color (FR-013); the selected piece has a thick ring (FR-027).
struct PieceView: View {
    let piece: Piece
    let isSelected: Bool
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(fill)
                .overlay(Circle().stroke(edge, lineWidth: max(1, size * 0.05)))
            if piece.kind == .king {
                Image(systemName: "crown.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Palette.crown.color)
                    .frame(width: size * 0.42)
            }
        }
        .padding(size * 0.12)
        .overlay {
            if isSelected {
                Circle()
                    .stroke(Palette.selection.color, lineWidth: max(2, size * 0.09))
                    .padding(size * 0.05)
            }
        }
        .frame(width: size, height: size)
    }

    private var fill: Color {
        piece.side == .light ? Palette.pieceLight.color : Palette.pieceDark.color
    }

    private var edge: Color {
        piece.side == .light ? Palette.pieceLightEdge.color : Palette.pieceDarkEdge.color
    }
}

#Preview("Pieces") {
    HStack(spacing: 0) {
        ForEach(
            [
                Piece(side: .light, kind: .man), Piece(side: .light, kind: .king),
                Piece(side: .dark, kind: .man), Piece(side: .dark, kind: .king),
            ], id: \.self
        ) { piece in
            VStack(spacing: 0) {
                PieceView(piece: piece, isSelected: false, size: 60)
                PieceView(piece: piece, isSelected: true, size: 60)
            }
        }
    }
    .background(Palette.boardDarkSquare.color)
}

#Preview("Pieces, dark") {
    HStack(spacing: 0) {
        PieceView(piece: Piece(side: .light, kind: .king), isSelected: true, size: 60)
        PieceView(piece: Piece(side: .dark, kind: .king), isSelected: false, size: 60)
    }
    .background(Palette.boardDarkSquare.color)
    .preferredColorScheme(.dark)
}
