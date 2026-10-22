import SwiftUI

/// Game setup: the opponent and, against the computer, the difficulty and side, then Start
/// (FR-007, FR-008). Choices are rows with check marks, which keep their full text at every text
/// size. Games against the computer cannot start until E4 (FR-011).
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
            } footer: {
                if router.setup.opponent == .computer {
                    Text("Games against the computer arrive in a later update.")
                        .foregroundStyle(Color.primary)
                        .accessibilityIdentifier("setup.computerNote")
                }
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
