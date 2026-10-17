import Foundation
import OSLog

/// Shared loggers (Constitution IX): the bundle identifier is the subsystem and each feature logs
/// under its own category. Interpolated values keep the default private redaction.
nonisolated enum Log {
    static let subsystem = Bundle.main.bundleIdentifier ?? "Hussein-Helmy.checkers"

    enum Category: String {
        case app
    }

    static let app = Logger(subsystem: subsystem, category: Category.app.rawValue)
}
