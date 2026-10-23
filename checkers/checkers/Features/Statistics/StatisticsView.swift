import SwiftUI

/// The player's record against the computer: wins, losses and draws at each difficulty, or a
/// line saying that no game is recorded yet (FR-STAT-01, FR-STAT-04; contracts/screens.md). The
/// blocks stack and scroll, so they fit at the largest text sizes, and all text is primary
/// (research R9). It has no buttons.
struct StatisticsView: View {
    let record: Record

    var body: some View {
        ScrollView {
            Group {
                if record.isEmpty {
                    empty
                } else {
                    VStack(alignment: .leading, spacing: 24) {
                        ForEach(Difficulty.allCases, id: \.self) { difficulty in
                            block(for: difficulty)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .navigationTitle("Statistics")
    }

    private var empty: some View {
        VStack(spacing: 8) {
            Text(StatisticsText.emptyTitle)
                .font(.headline)
            Text(StatisticsText.emptyMessage)
                .font(.body)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("statistics.empty")
    }

    /// A difficulty's name and its three counts, read by VoiceOver as one element.
    private func block(for difficulty: Difficulty) -> some View {
        let tally = record.tally(at: difficulty)
        return VStack(alignment: .leading, spacing: 4) {
            Text(StatisticsText.name(difficulty))
                .font(.headline)
            Text(StatisticsText.wins(tally.wins))
            Text(StatisticsText.losses(tally.losses))
            Text(StatisticsText.draws(tally.draws))
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(StatisticsText.label(tally, at: difficulty)))
        .accessibilityIdentifier("statistics.\(difficulty.rawValue)")
    }
}

/// A record with games at every level, for previews.
private let previewRecord = Record(
    easy: Record.Tally(wins: 3, losses: 1, draws: 2),
    medium: Record.Tally(wins: 1, losses: 4, draws: 0),
    hard: Record.Tally(wins: 0, losses: 1, draws: 0))

#Preview("Empty") {
    NavigationStack {
        StatisticsView(record: Record())
    }
}

#Preview("With a record") {
    NavigationStack {
        StatisticsView(record: previewRecord)
    }
}

#Preview("With a record, large text, dark") {
    NavigationStack {
        StatisticsView(record: previewRecord)
    }
    .environment(\.dynamicTypeSize, .accessibility5)
    .preferredColorScheme(.dark)
}

#Preview("Empty, large text, dark") {
    NavigationStack {
        StatisticsView(record: Record())
    }
    .environment(\.dynamicTypeSize, .accessibility5)
    .preferredColorScheme(.dark)
}
