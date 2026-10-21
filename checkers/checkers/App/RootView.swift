import SwiftUI

/// The app's navigation: Home at the root and every other screen pushed on top (research R2).
struct RootView: View {
    @Bindable var router: AppRouter

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView(router: router)
                .navigationDestination(for: Route.self) { route in
                    destination(for: route)
                }
        }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .setup:
            SetupView(router: router)
        case .game:
            if let session = router.session {
                GameView(session: session, router: router)
            }
        case .statistics:
            PlaceholderView(title: "Statistics")
        case .rules:
            PlaceholderView(title: "Rules")
        case .settings:
            PlaceholderView(title: "Settings")
        }
    }
}

#Preview {
    RootView(router: AppRouter(store: InMemorySetupStore()))
}
