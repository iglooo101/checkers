import CheckersEngine
import Foundation
import Testing

@testable import checkers

struct AnnouncerTests {
    @Test("The recording announcer keeps announcements in order, as spoken text")
    func recordsInOrder() {
        let announcer = RecordingAnnouncer()
        announcer.announce("Light to move")
        announcer.announce("A capture is required.")
        #expect(announcer.announcements == ["Light to move", "A capture is required."])
    }

    @Test("A game session takes the announcer it is given")
    func sessionTakesAnAnnouncer() {
        let announcer = RecordingAnnouncer()
        let session = GameSession(setup: .defaults, announcer: announcer)
        #expect(session.state == GameState())
        #expect(announcer.announcements.isEmpty)
    }
}
