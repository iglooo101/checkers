import CheckersEngine
import SwiftUI

/// The 8×8 board, sized to fit the space it is given with an 8-point inset, so squares stay at
/// least 44 points on a 375-point-wide iPhone (research R5). Dark squares take taps; pieces of
/// the side to move can be dragged (FR-020); nothing animates (FR-018).
struct BoardView: View {
    let session: GameSession

    /// A piece being dragged and how far it has moved.
    private struct Drag {
        let square: Square
        var offset: CGSize
    }

    @State private var drag: Drag?

    private static let inset: CGFloat = 8
    private static let frameWidth: CGFloat = 4
    private static let coordinateSpace = "board"

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
            .coordinateSpace(.named(Self.coordinateSpace))
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
                if session.targets.contains(square) {
                    Circle()
                        .fill(Palette.target.color)
                        .frame(width: size * 0.28, height: size * 0.28)
                }
                if let piece {
                    PieceView(
                        piece: piece, isSelected: isSelected,
                        isHinted: session.hintedPieces.contains(square), size: size
                    )
                    .offset(drag?.square == square ? drag?.offset ?? .zero : .zero)
                    .gesture(dragGesture(for: square, cell: size))
                }
            }
            .frame(width: size, height: size)
            .zIndex(drag?.square == square ? 1 : 0)
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

    /// Picks up a piece when the session accepts the drag and drops it on the square under the
    /// finger, or nowhere if the finger left the board (contract: Drags).
    private func dragGesture(for square: Square, cell: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .named(Self.coordinateSpace))
            .onChanged { value in
                if drag == nil, session.beginDrag(at: square) {
                    drag = Drag(square: square, offset: .zero)
                }
                if drag?.square == square {
                    drag?.offset = value.translation
                }
            }
            .onEnded { value in
                defer { drag = nil }
                guard drag?.square == square else { return }
                session.drop(on: self.square(at: value.location, cell: cell))
            }
    }

    /// The square under a point in the board's coordinate space, or `nil` off the board.
    private func square(at point: CGPoint, cell: CGFloat) -> Square? {
        guard cell > 0, point.x >= 0, point.y >= 0 else { return nil }
        let row = Int(point.y / cell)
        let column = Int(point.x / cell)
        guard row < 8, column < 8 else { return nil }
        return session.layout.square(row: row, column: column)
    }
}

#Preview("Start, with hints") {
    BoardView(session: GameSession(setup: .defaults))
}

#Preview("Selected piece and its targets, dark mode") {
    let session = GameSession(setup: .defaults)
    if let piece = Square(name: "c3") {
        session.tap(piece)
    }
    return BoardView(session: session)
        .preferredColorScheme(.dark)
}

#Preview("Dark at the bottom, with a king") {
    let pieces: [Square: Piece] = Dictionary(
        uniqueKeysWithValues: [
            ("d8", Piece(side: .light, kind: .king)), ("c3", Piece(side: .light, kind: .man)),
            ("f6", Piece(side: .dark, kind: .man)), ("a1", Piece(side: .dark, kind: .king)),
        ].compactMap { name, piece in Square(name: name).map { ($0, piece) } })
    return BoardView(
        session: GameSession(
            setup: .defaults, playerSide: .dark,
            state: GameState(position: Position(pieces), sideToMove: .dark)))
}
