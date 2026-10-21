import SwiftUI

/// A screen whose content a later epic delivers: Statistics (E5), Rules and Settings (E6)
/// (FR-003).
struct PlaceholderView: View {
    let title: LocalizedStringResource

    var body: some View {
        ScrollView {
            Spacer(minLength: 0)
        }
        .navigationTitle(Text(title))
    }
}

#Preview("Rules") {
    NavigationStack {
        PlaceholderView(title: "Rules")
    }
}

#Preview("Statistics, large text, dark") {
    NavigationStack {
        PlaceholderView(title: "Statistics")
    }
    .environment(\.dynamicTypeSize, .accessibility5)
    .preferredColorScheme(.dark)
}
