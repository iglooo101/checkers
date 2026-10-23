import CheckersEngine
import SwiftUI

/// Home: the app's first screen (FR-001, FR-002), with Continue first while a game is saved
/// (FR-NAV-02; specs/006-saving-and-statistics/contracts/screens.md).
struct HomeView: View {
    let router: AppRouter

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if router.hasSavedGame {
                    entry("Continue", identifier: "home.continue", prominent: true) {
                        router.continueGame()
                    }
                }
                entry("New game", identifier: "home.newGame", prominent: !router.hasSavedGame) {
                    router.newGame()
                }
                entry("Statistics", identifier: "home.statistics") { router.open(.statistics) }
                entry("Rules", identifier: "home.rules") { router.open(.rules) }
                entry("Settings", identifier: "home.settings") { router.open(.settings) }
            }
            .padding()
        }
        .navigationTitle("Checkers")
    }

    @ViewBuilder
    private func entry(
        _ title: LocalizedStringResource, identifier: String, prominent: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        let button = Button(action: action) {
            Text(title)
                .foregroundStyle(prominent ? Color.onAccent : Color.accentColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .controlSize(.large)
        .accessibilityIdentifier(identifier)
        if prominent {
            button.buttonStyle(.borderedProminent)
        } else {
            button.buttonStyle(.bordered)
        }
    }
}

#Preview("Home") {
    NavigationStack {
        HomeView(router: AppRouter(store: InMemorySetupStore()))
    }
}

#Preview("Home, large text, dark") {
    NavigationStack {
        HomeView(router: AppRouter(store: InMemorySetupStore()))
    }
    .environment(\.dynamicTypeSize, .accessibility5)
    .preferredColorScheme(.dark)
}

/// A router over an in-memory saved game, so Home offers Continue.
@MainActor
private func routerWithSavedGame() -> AppRouter {
    let saved = SavedGame(setup: .defaults, playerSide: .light, state: GameState())
    return AppRouter(store: InMemorySetupStore(), games: InMemorySavedGameStore(saved))
}

#Preview("Home with a saved game") {
    NavigationStack {
        HomeView(router: routerWithSavedGame())
    }
}

#Preview("Home with a saved game, large text, dark") {
    NavigationStack {
        HomeView(router: routerWithSavedGame())
    }
    .environment(\.dynamicTypeSize, .accessibility5)
    .preferredColorScheme(.dark)
}
