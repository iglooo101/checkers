import Foundation

/// The line each placeholder screen shows until its epic delivers it (FR-003).
enum PlaceholderText {
    static func message(for route: Route) -> LocalizedStringResource? {
        // Explicit returns: from a switch expression with an optional result the compiler extracts
        // only one literal into the String Catalog.
        switch route {
        case .rules: return "How to play American checkers will be explained here."
        case .settings: return "Board theme, sound effects and move hints will be set here."
        case .setup, .game, .statistics: return nil
        }
    }
}
