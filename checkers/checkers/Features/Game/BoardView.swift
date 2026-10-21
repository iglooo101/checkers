import CheckersEngine
import SwiftUI

/// The 8×8 board, sized to fit the space it is given with an 8-point inset, so squares stay at
/// least 44 points on a 375-point-wide iPhone (research R5). Dark squares take taps; nothing
/// animates (FR-018).
struct BoardView: View {
    let session: GameSession

    private static let inset: CGFloat = 8
    private static let frameWidth: CGFloat = 4

    var body: some View {
        GeometryReader { proxy in
            let side = max(0, min(proxy.size.width, proxy.size.height) - 2 * Self.inset)
            let cell = side / 8
            VStack(spacing: 0) {
                ForEach(0..<8, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<8, id: \.self) { column in
                            cellView(row: row, column: column, size: cell)
                        }
                    }
                }
            }
            .frame(width: side, height: side)
            .padding(Self.frameWidth)
            .background(Palette.boardFrame.color)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("board")
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .transaction { $0.animation = nil }
    }

    @ViewBuilder
    private func cellView(row: Int, column: Int, size: CGFloat) -> some View {
        if let square = session.layout.square(row: row, column: column) {
            let piece = session.state.position.piece(at: square)
            let isSelected = session.selection == square
            ZStack {
                Rectangle().fill(Palette.boardDarkSquare.color)
                if let piece {
                    PieceView(piece: piece, isSelected: isSelected, size: size)
                }
            }
            .frame(width: size, height: size)
            .contentShape(Rectangle())
            .onTapGesture { session.tap(square) }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(GameText.squareLabel(square, piece)))
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            .accessibilityIdentifier("square.\(square.name)")
            .accessibilityAction { session.tap(square) }
        } else {
            Rectangle()
                .fill(Palette.boardLightSquare.color)
                .frame(width: size, height: size)
                .accessibilityHidden(true)
        }
    }
}

#Preview("Start") {
    BoardView(session: GameSession(setup: .defaults))
}

#Preview("Dark at the bottom, dark mode") {
    BoardView(session: GameSession(setup: .defaults, playerSide: .dark))
        .preferredColorScheme(.dark)
}
