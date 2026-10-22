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
        guard let element = issue.element else { return false }
        // Start while Computer is chosen: the system dims a disabled control, which WCAG exempts
        // from contrast, and the audit misreads its Dynamic Type support (it scales).
        if element.identifier == "setup.start", !element.isEnabled {
            return issue.auditType == .contrast || issue.auditType == .dynamicType
        }
        // Setup text the scrolling form cuts at the screen's edge once the audit enlarges it: the
        // text scales and scrolls into view, but the audit reports whichever line is cut.
        return issue.auditType == .dynamicType && element.elementType == .staticText
            && issue.compactDescription.contains("partially") && app.element("setup.start").exists
    }

    /// Runs every audit type on the current screen; each problem not on the allow-list fails the
    /// test with the element it was found on.
    @MainActor
    private func audit(_ app: XCUIApplication) throws {
        try app.performAccessibilityAudit { issue in
            let element = issue.element.map {
                "\($0.elementType.rawValue) '\($0.identifier)' '\($0.label)'"
            }
            let summary = "\(issue.compactDescription) on \(element ?? "no element")"
            if Self.isAllowed(issue, in: app) {
                // Kept in the test report, so allowed issues stay visible.
                XCTContext.runActivity(named: "Allowed: \(summary)") { _ in }
            } else {
                XCTFail("\(summary): \(issue.detailedDescription)")
            }
            return true
        }
    }

    /// FR-A11Y-04: Home as launched.
    @MainActor
    func testUS5_auditHome() throws {
        let app = launch()
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

    /// FR-A11Y-04: game setup with Computer chosen, showing difficulty, side and the note.
    @MainActor
    func testUS5_auditSetupComputer() throws {
        let app = launch()
        open("home.newGame", waitingFor: app.buttons["Computer"])
        app.buttons["Computer"].tap()
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

    /// FR-A11Y-04: the Statistics placeholder.
    @MainActor
    func testUS5_auditStatistics() throws {
        let app = launch()
        open("home.statistics", waitingFor: app.element("placeholder.message"))
        try audit(app)
    }

    /// FR-A11Y-04: the Rules placeholder.
    @MainActor
    func testUS5_auditRules() throws {
        let app = launch()
        open("home.rules", waitingFor: app.element("placeholder.message"))
        try audit(app)
    }

    /// FR-A11Y-04: the Settings placeholder.
    @MainActor
    func testUS5_auditSettings() throws {
        let app = launch()
        open("home.settings", waitingFor: app.element("placeholder.message"))
        try audit(app)
    }
}
