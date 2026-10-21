import Foundation
import OSLog

/// Shared loggers (Constitution IX): the bundle identifier is the subsystem and each feature logs
/// under its own category. Interpolated values keep the default private redaction.
nonisolated enum Log {
    static let subsystem = Bundle.main.bundleIdentifier ?? "Hussein-Helmy.checkers"

    enum Category: String, CaseIterable {
        case app
        case game
        case setup
    }

    static let app = Logger(subsystem: subsystem, category: Category.app.rawValue)
    static let game = Logger(subsystem: subsystem, category: Category.game.rawValue)
    static let setup = Logger(subsystem: subsystem, category: Category.setup.rawValue)
}
