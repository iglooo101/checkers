import XCTest

final class US2CaptureUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// FR-GAME-02, FR-MOVE-05: after c3–d4, f6–e5 Light must capture; tapping another Light man
    /// says so, and the capture removes the jumped piece.
    @MainActor
    func testUS2_captureRequired() {
        let app = XCUIApplication()
        app.launch()
        app.startTwoPlayerGame()
        app.move("c3", "d4")
        app.move("f6", "e5")
        XCTAssertEqual(app.element("game.turn").label, "Light to move · capture required")

        app.square("e3").tap()
        XCTAssertTrue(app.element("game.notice").waitForExistence(timeout: 2))
        XCTAssertEqual(app.element("game.notice").label, "A capture is required.")

        app.move("d4", "f6")
        XCTAssertEqual(app.square("e5").label, "e5, empty")
        XCTAssertEqual(app.square("f6").label, "f6, Light man")
        // Dark's man on e7 can now jump f6, so Dark must capture in turn.
        XCTAssertEqual(app.element("game.turn").label, "Dark to move · capture required")
    }
}
