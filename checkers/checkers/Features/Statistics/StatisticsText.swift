import Foundation

/// The Statistics screen's texts (specs/006-saving-and-statistics/contracts/screens.md,
/// "Statistics"). Counts are plural variations in the String Catalog ("1 win", "3 wins").
enum StatisticsText {
    /// The empty state's title, while no game is recorded.
    static let emptyTitle: LocalizedStringResource = "No games yet."
    /// The empty state's sentence.
    static let emptyMessage: LocalizedStringResource =
        "Finish a game against the computer to start your record."

    /// A difficulty's name, the title of its block.
    static func name(_ difficulty: Difficulty) -> LocalizedStringResource {
        switch difficulty {
        case .easy: "Easy"
        case .medium: "Medium"
        case .hard: "Hard"
        }
    }

    /// A count of wins: "1 win", "3 wins".
    static func wins(_ count: Int) -> LocalizedStringResource {
        "\(count) wins"
    }

    /// A count of losses: "1 loss", "0 losses".
    static func losses(_ count: Int) -> LocalizedStringResource {
        "\(count) losses"
    }

    /// A count of draws: "1 draw", "2 draws".
    static func draws(_ count: Int) -> LocalizedStringResource {
        "\(count) draws"
    }

    /// What VoiceOver reads for a difficulty's block, as one sentence: "Easy: 3 wins, 1 loss,
    /// 2 draws" (FR-025).
    static func label(_ tally: Record.Tally, at difficulty: Difficulty) -> LocalizedStringResource {
        let won = String(localized: wins(tally.wins))
        let lost = String(localized: losses(tally.losses))
        let drawn = String(localized: draws(tally.draws))
        switch difficulty {
        case .easy: return "Easy: \(won), \(lost), \(drawn)"
        case .medium: return "Medium: \(won), \(lost), \(drawn)"
        case .hard: return "Hard: \(won), \(lost), \(drawn)"
        }
    }
}
