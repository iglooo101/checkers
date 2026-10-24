import XCTest

/// FR-A11Y-04: every screen and state passes the accessibility audit with all audit types
/// (specs/004-accessibility/contracts/announcements.md, "Audited screens").
/// Failures do not stop a test, so one run reports every problem on a screen.
final class US5AccessibilityAuditUITests: XCTestCase {
    /// Launches the app and waits for Home.
    @MainActor
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.element("home.newGame").waitForExistence(timeout: 10))
        return app
    }

    /// Opens a Home button's screen and waits for an element on it.
    @MainActor
    private func open(_ button: String, waitingFor element: XCUIElement) {
        let app = XCUIApplication()
        app.element(button).tap()
        XCTAssertTrue(element.waitForExistence(timeout: 5), "\(button) did not open")
    }

    /// The plan's audit allow-list (FR-018): issues on system components the app cannot change.
    @MainActor
    private static func isAllowed(_ issue: XCUIAccessibilityAuditIssue, in app: XCUIApplication)
        -> Bool
    {
        guard issue.auditType == .dynamicType, issue.compactDescription.contains("partially")
        else { return false }
        // System alerts (the abandon question, the restore notices): their texts and buttons
        // scale (checked on screen at the largest size), but the audit reports the alert's texts,
        // sometimes without naming them, as partially unsupported.
        let alert = app.alerts.firstMatch
        if alert.exists {
            guard let element = issue.element else { return true }
            return element.elementType == .staticText && alert.staticTexts[element.label].exists
        }
        guard let element = issue.element else { return false }
        // Settings texts the scrolling form cuts at the screen's edge, since E6 US4 the Game
        // section's header and footer: they scale (checked on screen at the largest size), but
        // the audit reports whichever text is cut, as on setup.
        if app.switches["settings.moveHints"].exists {
            return element.elementType == .staticText
        }
        // Setup rows the scrolling form cuts at the screen's edge once the audit enlarges the
        // text, a line or Start below the computer's choices: they scale and scroll into view,
        // but the audit reports whichever row is cut.
        let isSetupRow = element.elementType == .staticText || element.identifier == "setup.start"
        return isSetupRow && app.element("setup.start").exists
    }

    /// Runs every audit type on the current screen; each problem not on the allow-list fails the
    /// test with the element it was found on. A system banner over the app, such as a fresh
    /// simulator's notifications on CI, is read as inaccessible text, so a screen with problems is
    /// audited once more after banners have gone; only problems found both times fail.
    @MainActor
    private func audit(_ app: XCUIApplication) throws {
        var problems = try findProblems(app)
        if !problems.isEmpty {
            _ = XCTWaiter.wait(for: [XCTestExpectation(description: "Banners gone")], timeout: 8)
            problems = try findProblems(app)
        }
        for problem in problems {
            XCTFail(problem)
        }
    }

    /// One audit with every audit type, returning the problems not on the allow-list.
    @MainActor
    private func findProblems(_ app: XCUIApplication) throws -> [String] {
        var problems: [String] = []
        try app.performAccessibilityAudit { issue in
            let element = issue.element.map {
                "\($0.elementType.rawValue) '\($0.identifier)' '\($0.label)'"
            }
            let summary = "\(issue.compactDescription) on \(element ?? "no element")"
            if Self.isAllowed(issue, in: app) {
                // Kept in the test report, so allowed issues stay visible.
                XCTContext.runActivity(named: "Allowed: \(summary)") { _ in }
            } else {
                problems.append("\(summary): \(issue.detailedDescription)")
            }
            return true
        }
        return problems
    }

    /// FR-A11Y-04: Home without a saved game (specs/006-saving-and-statistics/contracts/
    /// screens.md, "Audited states"). A text value reads as no saved game for this launch
    /// (research R10, checked by T001); `launch(replacing:with:)` would pass bytes instead.
    @MainActor
    func testUS5_auditHome() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-savedGame", "none"]
        app.launch()
        XCTAssertTrue(app.element("home.newGame").waitForExistence(timeout: 10))
        XCTAssertFalse(app.element("home.continue").exists)
        try audit(app)
    }

    /// FR-A11Y-04: Home with Continue, after leaving a game in progress.
    @MainActor
    func testUS5_auditHomeWithContinue() throws {
        let app = launch()
        app.startTwoPlayerGame()
        app.move("c3", "d4")
        app.chooseFromGameMenu("Home")
        XCTAssertTrue(app.element("home.continue").waitForExistence(timeout: 3))
        try audit(app)
    }

    /// FR-A11Y-04: the alert after an unreadable saved game, launched with damaged bytes.
    @MainActor
    func testUS5_auditRestoreAlertSave() throws {
        let app = XCUIApplication()
        app.launch(replacing: "savedGame", with: "not a saved game")
        XCTAssertTrue(
            app.alerts["Your previous game couldn't be restored."].waitForExistence(timeout: 10))
        try audit(app)
    }

    /// FR-A11Y-04: the alert after an unreadable record, launched with damaged bytes.
    @MainActor
    func testUS5_auditRestoreAlertRecord() throws {
        let app = XCUIApplication()
        app.launch(replacing: "record", with: "not a record")
        XCTAssertTrue(
            app.alerts["Your record couldn't be restored and starts again from zero."]
                .waitForExistence(timeout: 10))
        try audit(app)
    }

    /// FR-A11Y-04: game setup with Two players chosen.
    @MainActor
    func testUS5_auditSetupTwoPlayers() throws {
        let app = launch()
        open("home.newGame", waitingFor: app.buttons["Two players"])
        app.buttons["Two players"].tap()
        try audit(app)
    }

    /// FR-A11Y-04: game setup with Computer chosen, showing difficulty, side and Start.
    @MainActor
    func testUS5_auditSetupComputer() throws {
        let app = launch()
        open("home.newGame", waitingFor: app.buttons["Computer"])
        app.buttons["Computer"].tap()
        try audit(app)
    }

    /// FR-A11Y-04: the "Abandon current game?" alert, after Start with a game saved.
    @MainActor
    func testUS5_auditAbandonAlert() throws {
        let app = launch()
        app.startTwoPlayerGame()
        app.move("c3", "d4")
        app.chooseFromGameMenu("Home")
        open("home.newGame", waitingFor: app.buttons["Two players"])
        app.buttons["Two players"].tap()
        app.scrolledTo(app.element("setup.start")).tap()
        XCTAssertTrue(app.alerts["Abandon current game?"].waitForExistence(timeout: 3))
        try audit(app)
    }

    /// FR-A11Y-04: the game screen as a new game.
    @MainActor
    func testUS5_auditNewGame() throws {
        let app = launch()
        app.startTwoPlayerGame()
        try audit(app)
    }

    /// FR-A11Y-04: the game screen with a piece selected and its targets marked.
    @MainActor
    func testUS5_auditSelectedPiece() throws {
        let app = launch()
        app.startTwoPlayerGame()
        app.square("c3").tap()
        try audit(app)
    }

    /// FR-A11Y-04: the game screen with the "capture required" notice.
    @MainActor
    func testUS5_auditCaptureNotice() throws {
        let app = launch()
        app.startTwoPlayerGame()
        app.move("c3", "d4")
        app.move("f6", "e5")
        app.square("e3").tap()
        XCTAssertTrue(app.element("game.notice").waitForExistence(timeout: 3))
        try audit(app)
    }

    /// FR-A11Y-04: the game screen with the result panel.
    @MainActor
    func testUS5_auditResultPanel() throws {
        let app = launch()
        app.startTwoPlayerGame()
        app.chooseFromGameMenu("Resign")
        app.confirm("Resign")
        XCTAssertTrue(app.element("result.panel").waitForExistence(timeout: 3))
        try audit(app)
    }

    /// FR-A11Y-04 (E4 FR-027): a computer game on the player's turn, after the computer's reply.
    /// The thinking header lasts about half a second, less than an audit run, so it is checked by
    /// unit tests and previews (specs/005-computer-opponent/research.md R12).
    @MainActor
    func testUS5_auditComputerGame() throws {
        let app = launch()
        app.startComputerGame(difficulty: "Easy", side: "Light")
        app.waitForTurn(startingWith: "Light to move")
        app.move("c3", "d4")
        app.waitForTurn(startingWith: "Light to move")
        try audit(app)
    }

    /// FR-A11Y-04 (E4 FR-027): a computer game with the result panel, after the player resigned.
    @MainActor
    func testUS5_auditComputerResult() throws {
        let app = launch()
        app.startComputerGame(difficulty: "Easy", side: "Light")
        app.waitForTurn(startingWith: "Light to move")
        app.chooseFromGameMenu("Resign")
        app.confirm("Resign")
        XCTAssertTrue(app.element("result.panel").waitForExistence(timeout: 3))
        try audit(app)
    }

    /// FR-A11Y-04: Statistics with no game recorded, launched with an empty record
    /// (specs/006-saving-and-statistics/contracts/screens.md, "Audited states").
    @MainActor
    func testUS5_auditStatistics() throws {
        let app = XCUIApplication()
        app.launch(replacing: "record", with: StoredValues.emptyRecord)
        XCTAssertTrue(app.element("home.newGame").waitForExistence(timeout: 10))
        open("home.statistics", waitingFor: app.element("statistics.empty"))
        try audit(app)
    }

    /// FR-A11Y-04: Statistics with games at every level, launched with that record.
    @MainActor
    func testUS5_auditStatisticsRecord() throws {
        let app = XCUIApplication()
        app.launch(replacing: "record", with: StoredValues.fullRecord)
        XCTAssertTrue(app.element("home.newGame").waitForExistence(timeout: 10))
        open("home.statistics", waitingFor: app.element("statistics.hard"))
        try audit(app)
    }

    /// FR-A11Y-04: Rules at its top (specs/007-settings-themes-sound-and-rules/contracts/
    /// screens.md).
    @MainActor
    func testUS5_auditRules() throws {
        let app = launch()
        open("home.rules", waitingFor: app.element("rules.board.title"))
        try audit(app)
    }

    /// FR-A11Y-04: Settings (specs/007-settings-themes-sound-and-rules/contracts/screens.md).
    @MainActor
    func testUS5_auditSettings() throws {
        let app = launch()
        open("home.settings", waitingFor: app.switches["settings.moveHints"].firstMatch)
        try audit(app)
    }
}
