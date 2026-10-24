import CheckersEngine
import SwiftUI

/// The Rules screen: one scrolling page of seven headed sections, each with its text and its
/// pictures (FR-020, FR-021; specs/007-settings-themes-sound-and-rules/contracts/screens.md).
/// VoiceOver moves between the sections by their headings (FR-025).
struct RulesView: View {
    /// The pictures' widest size, so a board stays a picture beside the text.
    private static let pictureWidth: CGFloat = 320

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                ForEach(RulesContent.sections) { section in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(section.title)
                            .font(.title2.weight(.semibold))
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityIdentifier("rules.\(section.id).title")
                        Text(section.text)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("rules.\(section.id).text")
                        ForEach(Array(section.pictures.enumerated()), id: \.offset) { item in
                            pictureView(item.element)
                                .frame(maxWidth: Self.pictureWidth)
                                .frame(maxWidth: .infinity)
                                .accessibilityIdentifier(
                                    Self.pictureIdentifier(section: section.id, index: item.offset))
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Rules")
    }

    /// `rules.<id>.picture` for a section's first picture, then `picture2` (contracts/screens.md).
    private static func pictureIdentifier(section: String, index: Int) -> String {
        index == 0 ? "rules.\(section).picture" : "rules.\(section).picture\(index + 1)"
    }

    @ViewBuilder
    private func pictureView(_ picture: RulesPicture) -> some View {
        switch picture {
        case .board(let state, let selected, let description):
            BoardPicture(
                position: state.position, selected: selected, hinted: picture.hinted,
                targets: picture.targets, description: description)
        case .menu:
            MenuPicture(description: picture.description)
        }
    }
}

/// The game menu's Undo and Resign items, as the menu shows them (FR-021).
private struct MenuPicture: View {
    let description: LocalizedStringResource

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Label("Undo", systemImage: "arrow.uturn.backward")
                .padding()
            Divider()
            Label("Resign", systemImage: "flag")
                .padding()
        }
        .foregroundStyle(Color.primary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(.background.secondary))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(description))
        .accessibilityAddTraits(.isImage)
    }
}

#Preview("Rules") {
    NavigationStack {
        RulesView()
    }
}

#Preview("Rules, dark") {
    NavigationStack {
        RulesView()
    }
    .preferredColorScheme(.dark)
}

#Preview("Rules, large text, dark") {
    NavigationStack {
        RulesView()
    }
    .environment(\.dynamicTypeSize, .accessibility5)
    .preferredColorScheme(.dark)
}
