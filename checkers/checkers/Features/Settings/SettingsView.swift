import SwiftUI

/// Settings: the player's choices for every game, applied at once, also to the game in progress
/// (FR-001, FR-003; specs/007-settings-themes-sound-and-rules/contracts/screens.md).
struct SettingsView: View {
    @Bindable var router: AppRouter

    var body: some View {
        @Bindable var settings = router.settings
        Form {
            Section {
                Toggle("Move hints", isOn: $settings.moveHints)
                    .accessibilityIdentifier("settings.moveHints")
            } header: {
                Text("Game").foregroundStyle(Color.primary)
            } footer: {
                Text(
                    "Rings the pieces that can move and dots the squares the selected piece can go to."
                )
                .foregroundStyle(Color.primary)
            }
        }
        .navigationTitle("Settings")
    }
}

/// A router over in-memory stores, so previews never touch the device's storage.
@MainActor
private func previewRouter(moveHints: Bool = true) -> AppRouter {
    var values = SettingsValues.defaults
    values.moveHints = moveHints
    return AppRouter(
        store: InMemorySetupStore(), settingsStore: InMemorySettingsStore(values))
}

#Preview("Hints on") {
    NavigationStack {
        SettingsView(router: previewRouter())
    }
}

#Preview("Hints off, dark") {
    NavigationStack {
        SettingsView(router: previewRouter(moveHints: false))
    }
    .preferredColorScheme(.dark)
}

#Preview("Large text, dark") {
    NavigationStack {
        SettingsView(router: previewRouter())
    }
    .environment(\.dynamicTypeSize, .accessibility5)
    .preferredColorScheme(.dark)
}
