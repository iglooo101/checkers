import Foundation

/// A stored value the app could not read at launch, which Home reports once with an alert
/// (FR-SAVE-05, FR-STAT-06; specs/006-saving-and-statistics/contracts/screens.md, "Home").
enum RestoreNotice: Equatable {
    /// The saved game was discarded.
    case savedGame
    /// The record starts again from zero.
    case record

    /// The alert's title; the alert has no message.
    var title: LocalizedStringResource {
        switch self {
        case .savedGame:
            return "Your previous game couldn't be restored."
        case .record:
            return "Your record couldn't be restored and starts again from zero."
        }
    }
}
