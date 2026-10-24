import CheckersEngine
import SwiftUI

/// A still picture of a board, or of part of one, from Light's side, drawn like the game board
/// with the same squares, pieces and marks; it takes no input (FR-021, FR-013;
/// specs/007-settings-themes-sound-and-rules/research.md R5). The Rules pictures and the
/// Settings previews are board pictures.
struct BoardPicture: View {
    let position: Position
    /// The display rows and columns to draw, row 0 at the top (row 8) and column 0 on the left
    /// (column a); the whole board by default.
    var rows = 0..<8
    var columns = 0..<8
    var selected: Square?
    var hinted: Set<Square> = []
    var targets: Set<Square> = []
    /// What VoiceOver says about the picture; `nil` hides it, for a decorative picture.
    var description: LocalizedStringResource?
    @Environment(\.boardTheme) private var theme

    private static let layout = BoardLayout(bottomSide: .light)
    private static let frameWidth: CGFloat = 3

    var body: some View {
        GeometryReader { proxy in
            let cell = max(0, (proxy.size.width - 2 * Self.frameWidth) / CGFloat(columns.count))
            VStack(spacing: 0) {
                ForEach(rows, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(columns, id: \.self) { column in
                            cellView(row: row, column: column, size: cell)
                        }
                    }
                }
            }
            .padding(Self.frameWidth)
            .background(Palette.boardFrame.color(in: theme))
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityHidden(description == nil)
        .modifier(PictureLabel(description: description))
    }

    /// Width over height, frame included, so the picture keeps square cells at any width.
    private var aspectRatio: CGFloat {
        CGFloat(columns.count) / CGFloat(max(1, rows.count))
    }

    @ViewBuilder
    private func cellView(row: Int, column: Int, size: CGFloat) -> some View {
        if let square = Self.layout.square(row: row, column: column) {
            ZStack {
                Rectangle().fill(Palette.boardDarkSquare.color(in: theme))
                if targets.contains(square) {
                    Circle()
                        .fill(Palette.target.color(in: theme))
                        .frame(width: size * 0.28, height: size * 0.28)
                }
                if let piece = position.piece(at: square) {
                    PieceView(
                        piece: piece, isSelected: selected == square,
                        isHinted: hinted.contains(square), size: size)
                }
            }
            .frame(width: size, height: size)
        } else {
            Rectangle()
                .fill(Palette.boardLightSquare.color(in: theme))
                .frame(width: size, height: size)
        }
    }
}

/// Labels a picture as one image with its description, when it has one.
private struct PictureLabel: ViewModifier {
    let description: LocalizedStringResource?

    func body(content: Content) -> some View {
        if let description {
            content
                .accessibilityLabel(Text(description))
                .accessibilityAddTraits(.isImage)
        } else {
            content
        }
    }
}

/// The starting position with c3 selected: every mark the game draws with hints on.
@MainActor
private func everyMarkPicture() -> BoardPicture {
    let state = GameState()
    let selected = Square(name: "c3")
    return BoardPicture(
        position: state.position, selected: selected, hinted: Set(state.movablePieces),
        targets: Set(selected.map { state.targets(from: $0) } ?? []),
        description:
            "The Light man on c3 is selected. It can move to b4 or d4. The other men that can move have a thin ring."
    )
}

/// The top-left 4 × 4 corner with men and kings of both sides, as Settings previews a theme.
@MainActor
private func cornerPicture() -> BoardPicture {
    let pieces: [Square: Piece] = Dictionary(
        uniqueKeysWithValues: [
            ("b8", Piece(side: .dark, kind: .man)), ("d8", Piece(side: .dark, kind: .man)),
            ("a7", Piece(side: .dark, kind: .king)), ("c5", Piece(side: .light, kind: .man)),
            ("b6", Piece(side: .light, kind: .king)),
        ].compactMap { name, piece in Square(name: name).map { ($0, piece) } })
    return BoardPicture(position: Position(pieces), rows: 0..<4, columns: 0..<4)
}

#Preview("Every mark") {
    everyMarkPicture().padding()
}

#Preview("Every mark, dark") {
    everyMarkPicture().padding()
        .preferredColorScheme(.dark)
}

#Preview("Corner") {
    cornerPicture().frame(width: 88).padding()
}

#Preview("Corner, dark") {
    cornerPicture().frame(width: 88).padding()
        .preferredColorScheme(.dark)
}
