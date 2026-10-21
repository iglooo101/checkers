import SwiftUI

/// Game setup: the opponent, and Start (FR-007). Choices are rows with check marks, which keep
/// their full text at every text size.
struct SetupView: View {
    @Bindable var router: AppRouter

    var body: some View {
        Form {
            Section("Opponent") {
                Picker("Opponent", selection: $router.setup.opponent) {
                    Text("Computer").tag(Opponent.computer)
                    Text("Two players").tag(Opponent.twoPlayers)
                }
                .pickerStyle(.inline)
                .labelsHidden()
                .accessibilityIdentifier("setup.opponent")
            }
            Section {
                Button("Start") { router.startGame() }
                    .disabled(!router.setup.canStart)
                    .accessibilityIdentifier("setup.start")
            }
        }
        .navigationTitle("New game")
    }
}

#Preview("Two players") {
    NavigationStack {
        SetupView(router: AppRouter(store: InMemorySetupStore()))
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
