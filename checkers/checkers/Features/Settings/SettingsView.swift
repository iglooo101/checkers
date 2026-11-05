import CheckersEngine
import SwiftUI

/// Settings: the player's choices for every game, applied at once, also to the game in progress
/// (FR-001, FR-003; specs/007-settings-themes-sound-and-rules/contracts/screens.md).
struct SettingsView: View {
    /// The largest text size at which three theme names fit side by side on the narrowest iPhone.
    private static let largestSizeSideBySide = DynamicTypeSize.xLarge

    @Bindable var router: AppRouter
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        @Bindable var settings = router.settings
        Form {
            Section {
                themeChoices
            } header: {
                Text("Board theme").foregroundStyle(Color.primary)
            }
            Section {
                Toggle("Sound effects", isOn: $settings.soundEffects)
                    .accessibilityIdentifier("settings.soundEffects")
            } header: {
                Text("Sound").foregroundStyle(Color.primary)
            } footer: {
                // Shown while sounds cannot play; it goes once one plays again (FR-SND-05).
                if router.showsSoundNotice {
                    Text("Sound effects aren't available right now.")
                        .foregroundStyle(Color.primary)
                        .accessibilityIdentifier("settings.soundUnavailable")
                }
            }
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

    /// The themes side by side, so the whole form fits at the default text size (FR-SET-05), and
    /// one below the other once their names no longer fit. One layout that changes rather than two
    /// sets of views: the audit's text size checks report views that are replaced as the size
    /// changes.
    private var themeChoices: some View {
        let layout =
            dynamicTypeSize > Self.largestSizeSideBySide
            ? AnyLayout(VStackLayout(spacing: 16))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 8))
        return layout {
            ForEach(BoardTheme.allCases, id: \.self) { theme in
                let isChosen = router.settings.boardTheme == theme
                // One button per theme rather than an inline picker. Plain, or a tap anywhere in
                // the form's row would press all three.
                Button {
                    router.settings.boardTheme = theme
                } label: {
                    ThemeChoice(theme: theme, isChosen: isChosen)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(theme.name))
                .accessibilityIdentifier("settings.theme.\(theme.rawValue)")
                .accessibilityAddTraits(isChosen ? .isSelected : [])
            }
        }
    }
}

/// A theme's choice: a small board in that theme, its name below, and a checkmark beside the name
/// when it is chosen. All of it is hidden from VoiceOver, so it reads the button's label and whether
/// it is chosen (FR-013, FR-025). With only the visible name as its label, the button's text element
/// takes in the board, and the contrast audit measures the board's squares as the name's colors.
private struct ThemeChoice: View {
    let theme: BoardTheme
    let isChosen: Bool

    /// Dark men on b8 and d8, a Dark king on a7, a Light man on c5 and a Light king on b6: both
    /// sides' men and kings in the top-left corner from Light's side (contracts/screens.md).
    private static let position: Position = {
        let pieces: [(String, Piece)] = [
            ("b8", Piece(side: .dark, kind: .man)), ("d8", Piece(side: .dark, kind: .man)),
            ("a7", Piece(side: .dark, kind: .king)), ("c5", Piece(side: .light, kind: .man)),
            ("b6", Piece(side: .light, kind: .king)),
        ]
        return Position(
            Dictionary(
                uniqueKeysWithValues: pieces.compactMap { name, piece in
                    Square(name: name).map { ($0, piece) }
                }))
    }()

    private static let previewWidth: CGFloat = 72

    var body: some View {
        VStack(spacing: 8) {
            BoardPicture(position: Self.position, rows: 0..<4, columns: 0..<4)
                .frame(width: Self.previewWidth)
                .environment(\.boardTheme, theme)
            HStack(spacing: 4) {
                if isChosen {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                        .accessibilityHidden(true)
                }
                // Primary text, not the button's tint.
                Text(theme.name)
                    .foregroundStyle(Color.primary)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

/// A router over in-memory stores, so previews never touch the device's storage.
@MainActor
private func previewRouter(
    theme: BoardTheme = .classic, moveHints: Bool = true, soundsPlay: Bool = true
) -> AppRouter {
    var values = SettingsValues.defaults
    values.boardTheme = theme
    values.moveHints = moveHints
    return AppRouter(
        store: InMemorySetupStore(), settingsStore: InMemorySettingsStore(values),
        sounds: RecordingSoundPlayer(isAvailable: soundsPlay))
}

#Preview("Hints on") {
    NavigationStack {
        SettingsView(router: previewRouter())
    }
}

#Preview("Sounds unavailable") {
    NavigationStack {
        SettingsView(router: previewRouter(soundsPlay: false))
    }
}

#Preview("Sounds unavailable, large text, dark") {
    NavigationStack {
        SettingsView(router: previewRouter(soundsPlay: false))
    }
    .environment(\.dynamicTypeSize, .accessibility5)
    .preferredColorScheme(.dark)
}

#Preview("Modern, hints off, dark") {
    NavigationStack {
        SettingsView(router: previewRouter(theme: .modern, moveHints: false))
    }
    .preferredColorScheme(.dark)
}

#Preview("Playful") {
    NavigationStack {
        SettingsView(router: previewRouter(theme: .playful))
    }
}

#Preview("Large text, dark") {
    NavigationStack {
        SettingsView(router: previewRouter())
    }
    .environment(\.dynamicTypeSize, .accessibility5)
    .preferredColorScheme(.dark)
}
