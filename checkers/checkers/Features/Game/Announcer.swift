import Foundation
import SwiftUI

/// Speaks game events with VoiceOver (FR-A11Y-03). Injected into `GameSession` so tests can check
/// exactly what is announced (Constitution II.3).
protocol Announcer: AnyObject {
    func announce(_ text: LocalizedStringResource)
}

/// Posts announcements to VoiceOver; they are ignored while VoiceOver is off.
final class AccessibilityAnnouncer: Announcer {
    func announce(_ text: LocalizedStringResource) {
        AccessibilityNotification.Announcement(String(localized: text)).post()
    }
}

/// Keeps every announcement, as the text VoiceOver would speak, for tests and previews.
final class RecordingAnnouncer: Announcer {
    private(set) var announcements: [String] = []

    func announce(_ text: LocalizedStringResource) {
        announcements.append(String(localized: text))
    }
}
