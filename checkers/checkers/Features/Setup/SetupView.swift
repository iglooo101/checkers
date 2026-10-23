import CheckersEngine
import SwiftUI

/// Game setup: the opponent and, against the computer, the difficulty and side, then Start
/// (FR-007, FR-008). Choices are rows with check marks, which keep their full text at every text
/// size.
struct SetupView: View {
    @Bindable var router: AppRouter

    var body: some View {
        Form {
            Section {
                Picker("Opponent", selection: $router.setup.opponent) {
                    Text("Computer").tag(Opponent.computer)
                    Text("Two players").tag(Opponent.twoPlayers)
                }
                .pickerStyle(.inline)
                .labelsHidden()
                .accessibilityIdentifier("setup.opponent")
            } header: {
                Text("Opponent").foregroundStyle(Color.primary)
            }
            if router.setup.opponent == .computer {
                Section {
                    Picker("Difficulty", selection: $router.setup.difficulty) {
                        Text("Easy").tag(Difficulty.easy)
                        Text("Medium").tag(Difficulty.medium)
                        Text("Hard").tag(Difficulty.hard)
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                    .accessibilityIdentifier("setup.difficulty")
                } header: {
                    Text("Difficulty").foregroundStyle(Color.primary)
                }
                Section {
                    Picker("Side", selection: $router.setup.side) {
                        Text("Light").tag(SideChoice.light)
                        Text("Dark").tag(SideChoice.dark)
                        Text("Random").tag(SideChoice.random)
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                    .accessibilityIdentifier("setup.side")
                } header: {
                    Text("Side").foregroundStyle(Color.primary)
                }
            }
            Section {
                Button("Start") { router.startGame() }
                    .accessibilityIdentifier("setup.start")
            }
        }
        .navigationTitle("New game")
        .alert("Abandon current game?", isPresented: abandonBinding) {
            Button("Abandon", role: .destructive) { router.confirmAbandon() }
                .accessibilityIdentifier("setup.abandon.confirm")
            Button("Cancel", role: .cancel) { router.cancelAbandon() }
                .accessibilityIdentifier("setup.abandon.cancel")
        } message: {
            Text("Starting a new game discards the game in progress.")
        }
    }

    /// Shows the abandon question while the router asks it; dismissing it cancels.
    private var abandonBinding: Binding<Bool> {
        Binding(
            get: { router.isConfirmingAbandon },
            set: { isShowing in
                if !isShowing { router.cancelAbandon() }
            })
    }
}

#Preview("Two players") {
    NavigationStack {
        SetupView(router: AppRouter(store: InMemorySetupStore()))
    }
}

/// A router over an in-memory saved game that has just been asked to start, so setup shows
/// "Abandon current game?".
@MainActor
private func routerAskingToAbandon() -> AppRouter {
    let saved = SavedGame(setup: .defaults, playerSide: .light, state: GameState())
    let router = AppRouter(store: InMemorySetupStore(), games: InMemorySavedGameStore(saved))
    router.startGame()
    return router
}

#Preview("Abandon current game?") {
    NavigationStack {
        SetupView(router: routerAskingToAbandon())
    }
}

#Preview("Computer, large text, dark") {
    let store = InMemorySetupStore(GameSetup(opponent: .computer, difficulty: .easy, side: .light))
    return NavigationStack {
        SetupView(router: AppRouter(store: store))
    }
    .environment(\.dynamicTypeSize, .accessibility5)
    .preferredColorScheme(.dark)
}
