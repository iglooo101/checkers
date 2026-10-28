import XCTest

/// The scripted session on the phone (specs/008-release-1-0/research.md R5 and R6, spec FR-012
/// and FR-013): hitches measured over a whole session while `scripts/device.sh session` captures
/// the app's timing lines. It attaches to the app that script started with the session's saved
/// game and never launches it, so it runs only through that script; the blocking plan skips it.
final class DeviceSessionUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// One measured session that starts and ends on Home, so it can repeat: the saved game's
    /// moves, a game at each difficulty, then the other screens. It attaches to the running app;
    /// when the script passes the saved game's bytes in `SESSION_GAME` (`TEST_RUNNER_SESSION_GAME`
    /// to `xcodebuild`), it launches the app itself with them instead, for a run whose hitches
    /// XCTest can measure even if it cannot on an app it attached to (research R6).
    @MainActor
    func testUS2_scriptedSession() {
        let app = XCUIApplication()
        if let game = ProcessInfo.processInfo.environment["SESSION_GAME"] {
            app.launchArguments = [
                "-savedGame", "<\(game)>", "-soundEffects", "<true/>", "-moveHints", "<true/>",
            ]
            app.launch()
        } else {
            // activate() would launch the app if it were not running, without the session's game.
            guard app.state != .notRunning else {
                XCTFail("Start the app with scripts/device.sh session")
                return
            }
            app.activate()
        }
        guard app.element("home.newGame").waitForExistence(timeout: 10) else {
            XCTFail("Start the app with scripts/device.sh session")
            return
        }
        let options = XCTMeasureOptions()
        options.iterationCount = 1
        measure(metrics: [XCTHitchMetric(application: app)], options: options) {
            playSavedGame(app)
            playComputerGames(app)
            browseScreens(app)
        }
    }

    /// The steps of scripts/device-session-game.json, which `StorageTests` plays through the
    /// engine: Light's quiet moves by tap and by drag with Dark's replies, a capture, then a
    /// two-jump chain that crowns; one undo, then Home. The launch argument holds for the whole
    /// launch, so Continue opens the same position every time.
    @MainActor
    private func playSavedGame(_ app: XCUIApplication) {
        let resume = app.element("home.continue")
        XCTAssertTrue(resume.waitForExistence(timeout: 10))
        resume.tap()
        XCTAssertTrue(app.element("board").waitForExistence(timeout: 5))
        app.move("e1", "f2")
        app.move("e5", "f4")
        app.square("c3").press(forDuration: 0.2, thenDragTo: app.square("d4"))
        app.move("f4", "g3")
        app.move("f2", "h4")
        app.move("b6", "c5")
        app.move("d4", "b6")
        app.square("d8").tap()
        XCTAssertTrue(app.square("d8").label.hasPrefix("d8, Light king"))
        app.chooseFromGameMenu("Undo")
        XCTAssertTrue(app.square("d4").label.hasPrefix("d4, Light man"))
        app.chooseFromGameMenu("Home")
    }

    /// A game against the computer at each difficulty: three moves of the player's, each after
    /// the computer's reply.
    @MainActor
    private func playComputerGames(_ app: XCUIApplication) {
        for difficulty in ["Easy", "Medium", "Hard"] {
            app.startComputerGame(difficulty: difficulty, side: "Light")
            for _ in 1...3 {
                app.waitForTurn(startingWith: "Light to move", timeout: 10)
                playAnyTurn(app)
            }
            app.waitForTurn(startingWith: "Light to move", timeout: 10)
            app.chooseFromGameMenu("Home")
        }
    }

    /// Plays some legal turn for the player, found by the squares' VoiceOver labels, which do not
    /// depend on the hints setting: the first piece that can move, then a legal target until the
    /// turn ends (a chain goes on from the piece that jumped).
    @MainActor
    private func playAnyTurn(_ app: XCUIApplication) {
        squares(in: app, endingWith: ", can move").firstMatch.tap()
        let target = squares(in: app, endingWith: ", legal target").firstMatch
        while target.waitForExistence(timeout: 1) {
            target.tap()
        }
    }

    /// Rules scrolled to its end and back, Statistics, Settings and the setup form.
    @MainActor
    private func browseScreens(_ app: XCUIApplication) {
        app.element("home.rules").tap()
        XCTAssertTrue(app.element("rules.board.title").waitForExistence(timeout: 5))
        let end = app.element("rules.undoResign.picture")
        var swipes = 0
        while !end.exists && swipes < 12 {
            app.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(end.exists, "Rules did not scroll to its end")
        for _ in 0..<swipes {
            app.swipeDown()
        }
        goBack(app)

        // The phone's own record shows, or its empty state.
        app.element("home.statistics").tap()
        XCTAssertTrue(
            app.element("statistics.easy").waitForExistence(timeout: 5)
                || app.element("statistics.empty").exists)
        goBack(app)

        app.openSettingsFromHome()
        app.swipeUp()
        app.swipeDown()
        goBack(app)

        app.element("home.newGame").tap()
        let computer = app.buttons["Computer"]
        XCTAssertTrue(computer.waitForExistence(timeout: 5))
        computer.tap()
        app.swipeUp()
        app.swipeDown()
        goBack(app)
    }

    /// Returns to Home from a screen it pushed.
    @MainActor
    private func goBack(_ app: XCUIApplication) {
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.element("home.newGame").waitForExistence(timeout: 5))
    }

    /// The board squares whose labels end with this state.
    @MainActor
    private func squares(in app: XCUIApplication, endingWith state: String) -> XCUIElementQuery {
        app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'square.' AND label ENDSWITH %@", state))
    }
}
