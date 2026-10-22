import SwiftUI

/// A screen whose content a later epic delivers: Statistics (E5), Rules and Settings (E6). It
/// shows its title and one line saying what it will contain (FR-003).
struct PlaceholderView: View {
    let title: LocalizedStringResource
    let message: LocalizedStringResource

    var body: some View {
        ScrollView {
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding()
                .accessibilityIdentifier("placeholder.message")
        }
        .navigationTitle(Text(title))
    }
}

#Preview("Rules") {
    NavigationStack {
        PlaceholderView(
            title: "Rules", message: "How to play American checkers will be explained here.")
    }
}

#Preview("Statistics, large text, dark") {
    NavigationStack {
        PlaceholderView(
            title: "Statistics",
            message: "Your wins, losses and draws against the computer will appear here.")
    }
    .environment(\.dynamicTypeSize, .accessibility5)
    .preferredColorScheme(.dark)
}
