import Foundation

/// The line each placeholder screen shows until its story delivers it (FR-003).
enum PlaceholderText {
    static func message(for route: Route) -> LocalizedStringResource? {
        // Explicit returns: from a switch expression with an optional result the compiler extracts
        // only one literal into the String Catalog.
        switch route {
        case .rules: return "How to play American checkers will be explained here."
        case .setup, .game, .statistics, .settings: return nil
        }
    }
}
