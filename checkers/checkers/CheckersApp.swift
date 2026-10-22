import SwiftUI

@main
struct CheckersApp: App {
    @State private var router = AppRouter(store: UserDefaultsSetupStore(defaults: .standard))

    var body: some Scene {
        WindowGroup {
            RootView(router: router)
        }
    }
}
