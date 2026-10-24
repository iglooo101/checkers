import CheckersEngine
import SwiftUI

/// Settings: the player's choices for every game, applied at once, also to the game in progress
/// (FR-001, FR-003; specs/007-settings-themes-sound-and-rules/contracts/screens.md).
struct SettingsView: View {
    @Bindable var router: AppRouter

    var body: some View {
        @Bindable var settings = router.settings
        Form {
            Section {
                // One button per theme rather than an inline picker: a picker row merges its
                // label into one text element whose frame takes in the preview, and the contrast
                // audit then measures the board's squares as the name's colors.
                ForEach(BoardTheme.allCases, id: \.self) { theme in
                    let isChosen = settings.boardTheme == theme
                    Button {
                        settings.boardTheme = theme
                    } label: {
                        ThemeRow(theme: theme, isChosen: isChosen)
                    }
                    .accessibilityIdentifier("settings.theme.\(theme.rawValue)")
                    .accessibilityAddTraits(isChosen ? .isSelected : [])
                }
            } header: {
                Text("Board theme").foregroundStyle(Color.primary)
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
}

/// A theme's row: a small board in that theme, its name, and a checkmark when it is chosen. The
/// board and the checkmark are decorative, so VoiceOver reads the name and whether it is chosen
/// (FR-013, FR-025). At large text sizes the name goes below the board when they do not fit side
/// by side.
private struct ThemeRow: View {
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
        HStack(spacing: 16) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) {
                    preview
                    name
                }
                VStack(alignment: .leading, spacing: 8) {
                    preview
                    name
                }
            }
            Spacer(minLength: 0)
            if isChosen {
                Image(systemName: "checkmark")
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 4)
    }

    /// Primary text, not the button's tint.
    private var name: some View {
        Text(theme.name).foregroundStyle(Color.primary)
    }

    private var preview: some View {
        BoardPicture(position: Self.position, rows: 0..<4, columns: 0..<4)
            .frame(width: Self.previewWidth)
            .environment(\.boardTheme, theme)
    }
}

/// A router over in-memory stores, so previews never touch the device's storage.
@MainActor
private func previewRouter(theme: BoardTheme = .classic, moveHints: Bool = true) -> AppRouter {
    var values = SettingsValues.defaults
    values.boardTheme = theme
    values.moveHints = moveHints
    return AppRouter(
        store: InMemorySetupStore(), settingsStore: InMemorySettingsStore(values))
}

#Preview("Hints on") {
    NavigationStack {
        SettingsView(router: previewRouter())
    }
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
