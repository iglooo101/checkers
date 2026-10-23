import XCTest

/// The record against the computer on the Statistics screen
/// (specs/006-saving-and-statistics/spec.md, US3; contracts/screens.md, "Statistics").
final class US3StatisticsUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// Opens Statistics from Home and reads Easy's losses from its block's VoiceOver label
    /// ("Easy: 3 wins, 1 loss, 2 draws"), 0 while the empty state shows.
    @MainActor
    private func easyLosses(in app: XCUIApplication) -> Int {
        let statistics = app.element("home.statistics")
        XCTAssertTrue(statistics.waitForExistence(timeout: 10))
        statistics.tap()
        let easy = app.element("statistics.easy")
        guard easy.waitForExistence(timeout: 5) else {
            XCTAssertTrue(app.element("statistics.empty").exists, "Statistics shows nothing")
            return 0
        }
        guard let losses = easy.label.firstMatch(of: /(\d+) loss/), let count = Int(losses.1)
        else {
            XCTFail("No losses in \"\(easy.label)\"")
            return 0
        }
        return count
    }

    /// FR-STAT-02, FR-STAT-04: a resigned game against Easy adds one loss to Easy's block. Earlier
    /// tests leave games recorded, so the test compares counts before and after.
    @MainActor
    func testUS3_finishedGameCounts() {
        let app = XCUIApplication()
        app.launch()
        let before = easyLosses(in: app)
        app.navigationBars.buttons.firstMatch.tap()

        app.startComputerGame(difficulty: "Easy", side: "Light")
        app.chooseFromGameMenu("Resign")
        app.confirm("Resign")
        let home = app.element("result.home")
        XCTAssertTrue(home.waitForExistence(timeout: 3))
        home.tap()

        XCTAssertEqual(easyLosses(in: app), before + 1)
    }

    /// FR-STAT-01, FR-STAT-04: with no game recorded, Statistics says so in two sentences.
    @MainActor
    func testUS3_emptyState() {
        let app = XCUIApplication()
        app.launch(replacing: "record", with: StoredValues.emptyRecord)
        let statistics = app.element("home.statistics")
        XCTAssertTrue(statistics.waitForExistence(timeout: 10))
        statistics.tap()

        XCTAssertTrue(app.element("statistics.empty").waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["No games yet."].exists)
        XCTAssertTrue(
            app.staticTexts["Finish a game against the computer to start your record."].exists)
        XCTAssertFalse(app.element("statistics.easy").exists)
    }
}
