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
