import CheckersEngine
import SwiftUI

/// The game screen: the turn indicator and any notice above the board, the game menu, and the
/// result panel over the board once the game ends. No other game information (FR-012).
struct GameView: View {
    let session: GameSession
    let router: AppRouter

    @State private var isConfirmingResign = false

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
                .overlay {
                    if let result = session.resultText {
                        ResultPanel(
                            text: result, playAgain: { router.playAgain() },
                            home: { router.requestHome() })
                    }
                }
        }
        .padding(.top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !session.isOver {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Undo", systemImage: "arrow.uturn.backward") { session.undo() }
                            .disabled(!session.canUndo)
                            .accessibilityIdentifier("game.menu.undo")
                        Button("Resign", role: .destructive) { isConfirmingResign = true }
                            .accessibilityIdentifier("game.menu.resign")
                    } label: {
                        Label("Game menu", systemImage: "ellipsis.circle")
                    }
                    .accessibilityIdentifier("game.menu")
                }
            }
        }
        // An alert, not a confirmation dialog: from a toolbar item iOS shows a dialog as a popover
        // without a Cancel button.
        .alert(Text(GameText.resignTitle(session.resigningSide)), isPresented: $isConfirmingResign)
        {
            Button("Resign", role: .destructive) { session.resign() }
                .accessibilityIdentifier("game.resign.confirm")
            Button("Cancel", role: .cancel) {}
                .accessibilityIdentifier("game.resign.cancel")
        }
    }
}

#Preview("New game") {
    NavigationStack {
        GameView(
            session: GameSession(setup: .defaults), router: AppRouter(store: InMemorySetupStore()))
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
        GameView(session: session, router: AppRouter(store: InMemorySetupStore()))
    }
}

#Preview("Finished, large text, dark") {
    let session = GameSession(setup: .defaults)
    session.resign()
    return NavigationStack {
        GameView(session: session, router: AppRouter(store: InMemorySetupStore()))
    }
    .environment(\.dynamicTypeSize, .accessibility5)
    .preferredColorScheme(.dark)
}
