import Observation

/// The settings the app uses, shared by the router, every game session and the Settings screen
/// (research R2). A change is visible to every observer at once and saved before the setter
/// returns (FR-003, FR-004).
@Observable
final class AppSettings {
    var boardTheme: BoardTheme {
        didSet { save() }
    }
    var soundEffects: Bool {
        didSet { save() }
    }
    var moveHints: Bool {
        didSet { save() }
    }

    @ObservationIgnored private let store: any SettingsStore

    /// Loads the stored settings; the router builds it, so it exists before the first frame.
    init(store: any SettingsStore) {
        self.store = store
        let values = store.load()
        boardTheme = values.boardTheme
        soundEffects = values.soundEffects
        moveHints = values.moveHints
    }

    /// The current values.
    var values: SettingsValues {
        SettingsValues(boardTheme: boardTheme, soundEffects: soundEffects, moveHints: moveHints)
    }

    private func save() {
        store.save(values)
    }
}
