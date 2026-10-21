import SwiftUI

@main
struct CheckersApp: App {
    @State private var router = AppRouter(store: InMemorySetupStore())

    var body: some Scene {
        WindowGroup {
            RootView(router: router)
        }
    }
}
