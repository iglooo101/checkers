import XCTest

/// Saved data that cannot be read (specs/006-saving-and-statistics/spec.md, US4;
/// contracts/screens.md, "Home"): launched with damaged bytes in place of the saved game or the
/// record, Home says so once and the app goes on as usual.
final class US4RestoreFailureUITests: XCTestCase {
    static let saveFailure = "Your previous game couldn't be restored."
    static let recordFailure = "Your record couldn't be restored and starts again from zero."

    override func setUp() {
        continueAfterFailure = false
    }

    /// Waits for the restore alert with this title on Home and answers OK. Alert buttons are
    /// found by label, as XCUITest does not see their identifiers, and the first match is taken,
    /// as iOS can expose an alert's button more than once; the alert must then close.
    @MainActor
    private func answerRestoreAlert(_ title: String, in app: XCUIApplication) {
        let alert = app.alerts[title]
        XCTAssertTrue(alert.waitForExistence(timeout: 10), "No alert \"\(title)\"")
        let okButton = alert.buttons["OK"].firstMatch
        XCTAssertTrue(okButton.exists, "No OK button in \"\(title)\"")
        okButton.tap()
        XCTAssertTrue(alert.waitForNonExistence(timeout: 3), "\"\(title)\" stayed")
    }

    /// FR-SAVE-05: a saved game that is not JSON is reported, Home offers no Continue, and a new
    /// game starts without "Abandon current game?".
    @MainActor
    func testUS4_damagedSave() {
        let app = XCUIApplication()
        app.launch(replacing: "savedGame", with: "not a saved game")
        answerRestoreAlert(Self.saveFailure, in: app)
        XCTAssertTrue(app.element("home.newGame").exists)
        XCTAssertFalse(app.element("home.continue").exists)

        app.element("home.newGame").tap()
        let twoPlayers = app.buttons["Two players"]
        XCTAssertTrue(twoPlayers.waitForExistence(timeout: 5))
        twoPlayers.tap()
        app.scrolledTo(app.element("setup.start")).tap()
        XCTAssertTrue(app.element("game.turn").waitForExistence(timeout: 5))
        XCTAssertFalse(app.alerts["Abandon current game?"].exists)
    }

    /// FR-STAT-06: a record that is not JSON is reported, and Statistics starts from zero.
    @MainActor
    func testUS4_damagedRecord() {
        let app = XCUIApplication()
        app.launch(replacing: "record", with: "not a record")
        answerRestoreAlert(Self.recordFailure, in: app)

        app.element("home.statistics").tap()
        XCTAssertTrue(app.element("statistics.empty").waitForExistence(timeout: 5))
    }

    /// FR-SAVE-05, FR-STAT-06: with both damaged, the saved game's alert comes first, then the
    /// record's.
    @MainActor
    func testUS4_bothDamaged() {
        let app = XCUIApplication()
        app.launch(replacing: ["savedGame": "not a saved game", "record": "not a record"])
        answerRestoreAlert(Self.saveFailure, in: app)
        answerRestoreAlert(Self.recordFailure, in: app)
        XCTAssertFalse(app.element("home.continue").exists)
    }
}
