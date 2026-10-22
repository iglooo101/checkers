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
        // Leaving goes through the menu's Home, which asks first while the game is in progress
        // (FR-042), so the system back button is hidden.
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if !session.isOver {
                        Button("Undo", systemImage: "arrow.uturn.backward") { session.undo() }
                            .disabled(!session.canUndo)
                            .accessibilityIdentifier("game.menu.undo")
                        Button("Resign", role: .destructive) { isConfirmingResign = true }
                            .accessibilityIdentifier("game.menu.resign")
                    }
                    Button("Rules", systemImage: "book") { router.open(.rules) }
                        .accessibilityIdentifier("game.menu.rules")
                    Button("Settings", systemImage: "gear") { router.open(.settings) }
                        .accessibilityIdentifier("game.menu.settings")
                    Button("Home", systemImage: "house") { router.requestHome() }
                        .accessibilityIdentifier("game.menu.home")
                } label: {
                    Label("Game menu", systemImage: "ellipsis.circle")
                }
                .accessibilityIdentifier("game.menu")
            }
        }
        // Alerts, not confirmation dialogs: from a toolbar item iOS shows a dialog as a popover
        // without a Cancel button.
        .alert(Text(GameText.resignTitle(session.resigningSide)), isPresented: $isConfirmingResign)
        {
            Button("Resign", role: .destructive) { session.resign() }
                .accessibilityIdentifier("game.resign.confirm")
            Button("Cancel", role: .cancel) {}
                .accessibilityIdentifier("game.resign.cancel")
        }
        .alert("Leave this game?", isPresented: leaveBinding) {
            Button("Leave", role: .destructive) { router.confirmLeave() }
                .accessibilityIdentifier("game.leave.confirm")
            Button("Cancel", role: .cancel) { router.cancelLeave() }
                .accessibilityIdentifier("game.leave.cancel")
        } message: {
            Text("It can't be resumed yet.")
        }
    }

    /// Shows the leave confirmation while the router asks for it; dismissing it cancels.
    private var leaveBinding: Binding<Bool> {
        Binding(
            get: { router.isConfirmingLeave },
            set: { isShowing in
                if !isShowing { router.cancelLeave() }
            })
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
