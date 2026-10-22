import SwiftUI

/// Home: the app's first screen (FR-001, FR-002). Continue arrives with saving in E5.
struct HomeView: View {
    let router: AppRouter

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                entry("New game", identifier: "home.newGame", prominent: true) { router.newGame() }
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
