import SwiftUI

@main
struct CheckersApp: App {
    @State private var router = AppRouter(
        store: UserDefaultsSetupStore(defaults: .standard),
        games: UserDefaultsSavedGameStore(defaults: .standard),
        records: UserDefaultsRecordStore(defaults: .standard),
        settingsStore: UserDefaultsSettingsStore(defaults: .standard),
        sounds: AudioSoundPlayer())
    /// Logs the diagnostics the system delivers, for the app's lifetime (FR-008).
    @State private var diagnostics = DiagnosticsSubscriber(log: OSLogDiagnosticsLog())

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView(router: router)
                // After the first frame, so MetricKit never delays launch (Constitution VII.1).
                .task { diagnostics.start() }
        }
        // The system may end the app at any time once it is in the background (FR-SAVE-01).
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                router.saveNow()
            }
        }
    }
}
