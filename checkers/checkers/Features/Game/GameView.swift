import CheckersEngine
import SwiftUI

/// The game screen: the turn indicator above the board, and no other game information
/// (FR-012).
struct GameView: View {
    let session: GameSession

    var body: some View {
        VStack(spacing: 12) {
            Text(session.turnText)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("game.turn")
                .padding(.horizontal)
            if let notice = session.notice {
                Text(GameText.notice(notice))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("game.notice")
                    .padding(.horizontal)
            }
            BoardView(session: session)
        }
        .padding(.top)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("New game") {
    NavigationStack {
        GameView(session: GameSession(setup: .defaults))
    }
}

#Preview("Capture required, with the notice") {
    let session = GameSession(
        setup: .defaults,
        state: GameState(
            position: Position(
                Dictionary(
                    uniqueKeysWithValues: [
                        ("c3", Piece(side: .light, kind: .man)),
                        ("a1", Piece(side: .light, kind: .man)),
                        ("d4", Piece(side: .dark, kind: .man)),
                        ("f8", Piece(side: .dark, kind: .king)),
                    ].compactMap { name, piece in Square(name: name).map { ($0, piece) } })),
            sideToMove: .light))
    if let manThatCannotCapture = Square(name: "a1") {
        session.tap(manThatCannotCapture)
    }
    return NavigationStack {
        GameView(session: session)
    }
}

#Preview("After a move, large text, dark") {
    let session = GameSession(setup: .defaults)
    if let from = Square(name: "c3"), let to = Square(name: "d4") {
        session.tap(from)
        session.tap(to)
    }
    return NavigationStack {
        GameView(session: session)
    }
    .environment(\.dynamicTypeSize, .accessibility5)
    .preferredColorScheme(.dark)
}
