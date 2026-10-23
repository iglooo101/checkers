import SwiftUI

@main
struct CheckersApp: App {
    @State private var router = AppRouter(
        store: UserDefaultsSetupStore(defaults: .standard),
        games: UserDefaultsSavedGameStore(defaults: .standard),
        records: UserDefaultsRecordStore(defaults: .standard))

    var body: some Scene {
        WindowGroup {
            RootView(router: router)
        }
    }
}
