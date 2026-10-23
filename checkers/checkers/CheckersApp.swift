import SwiftUI

@main
struct CheckersApp: App {
    @State private var router = AppRouter(
        store: UserDefaultsSetupStore(defaults: .standard),
        games: UserDefaultsSavedGameStore(defaults: .standard),
        records: UserDefaultsRecordStore(defaults: .standard))

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView(router: router)
        }
        // The system may end the app at any time once it is in the background (FR-SAVE-01).
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                router.saveNow()
            }
        }
    }
}
