import UIKit
import XCTest

/// The six store screenshots (specs/008-release-1-0/contracts/store-listing.md, spec FR-019),
/// taken by `scripts/screenshots.sh` through `Screenshots.xctestplan`; the blocking plan skips
/// them. Every state comes from launch arguments or from moves in a two-player game, so each
/// picture is the same on every run: a game against the computer is only ever shown with the
/// player to move, since the computer draws each turn with a fresh seed.
final class ScreenshotUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// A game against the computer at Medium, ten turns in, with Light, the player, to move.
    static let computerGame = """
        {"version": 1, "setup": {"opponent": "computer", "difficulty": "medium", "side": "light"},
         "playerSide": "light",
         "state": {"position": {"light": 1983, "dark": 3688628224, "kings": 0},
          "sideToMove": "light", "chainSquare": null, "outcome": "inProgress",
          "noProgressCount": 0, "turns": []}}
        """

    /// A two-player game, fourteen turns in, in which Light must jump c3–e5 and then e5–c7.
    static let captureChain = """
        {"version": 1, "setup": {"opponent": "twoPlayers", "difficulty": "easy", "side": "light"},
         "playerSide": null,
         "state": {"position": {"light": 4061, "dark": 2107744256, "kings": 0},
          "sideToMove": "light", "chainSquare": null, "outcome": "inProgress",
          "noProgressCount": 0, "turns": []}}
        """

    /// A two-player game, twenty-two turns in, in which Light's man on e7 can step to d8.
    static let crowning = """
        {"version": 1, "setup": {"opponent": "twoPlayers", "difficulty": "easy", "side": "light"},
         "playerSide": null,
         "state": {"position": {"light": 75510489, "dark": 1529872384, "kings": 0},
          "sideToMove": "light", "chainSquare": null, "outcome": "inProgress",
          "noProgressCount": 0, "turns": []}}
        """

    /// A version 1 record with games at every level.
    static let record = """
        {"version": 1, "easy": {"wins": 7, "losses": 1, "draws": 1},
         "medium": {"wins": 4, "losses": 3, "draws": 2},
         "hard": {"wins": 1, "losses": 4, "draws": 1}}
        """

    /// Home, with a saved game, so Continue shows.
    @MainActor
    func testUS4_home() {
        let app = launch(savedGame: Self.computerGame)
        XCTAssertTrue(app.element("home.continue").waitForExistence(timeout: 10))
        capture("01-home")
    }

    /// The game against the computer, its movable pieces hinted.
    @MainActor
    func testUS4_computerGame() {
        let app = launch(savedGame: Self.computerGame)
        resume(app)
        app.waitForTurn(startingWith: "Light to move")
        XCTAssertEqual(app.square("c3").label, "c3, Light man, can move")
        capture("02-computer-game")
    }

    /// The chain's first jump played: the piece stays selected and its next target is marked.
    @MainActor
    func testUS4_captureChain() {
        let app = launch(savedGame: Self.captureChain)
        resume(app)
        app.move("c3", "e5")
        XCTAssertEqual(app.square("e5").label, "e5, Light man, selected")
        XCTAssertEqual(app.square("c7").label, "c7, empty, legal target")
        capture("03-capture-chain")
    }

    /// The crowning step played: a Light king on d8, and Dark to move.
    @MainActor
    func testUS4_king() {
        let app = launch(savedGame: Self.crowning)
        resume(app)
        app.move("e7", "d8")
        XCTAssertTrue(app.square("d8").label.hasPrefix("d8, Light king"))
        app.waitForTurn(startingWith: "Dark to move")
        capture("04-king")
    }

    /// Rules, at the top of the page.
    @MainActor
    func testUS4_rules() {
        let app = launch(savedGame: Self.computerGame)
        let rules = app.element("home.rules")
        XCTAssertTrue(rules.waitForExistence(timeout: 10))
        rules.tap()
        XCTAssertTrue(app.element("rules.board.title").waitForExistence(timeout: 5))
        capture("05-rules")
    }

    /// Statistics, with the record's three levels.
    @MainActor
    func testUS4_statistics() {
        let app = launch(savedGame: Self.computerGame)
        let statistics = app.element("home.statistics")
        XCTAssertTrue(statistics.waitForExistence(timeout: 10))
        statistics.tap()
        XCTAssertTrue(app.element("statistics.easy").waitForExistence(timeout: 5))
        XCTAssertTrue(app.element("statistics.hard").exists)
        capture("06-statistics")
    }

    /// Launches with this saved game, the record and the default board settings, so Home shows
    /// no restore notice whatever earlier tests stored.
    @MainActor
    private func launch(savedGame: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launch(
            replacing: ["savedGame": savedGame, "record": Self.record],
            settings: ["boardTheme": "classic", "moveHints": "<true/>"])
        return app
    }

    /// Opens the saved game from Home.
    @MainActor
    private func resume(_ app: XCUIApplication) {
        let resume = app.element("home.continue")
        XCTAssertTrue(resume.waitForExistence(timeout: 10))
        resume.tap()
        XCTAssertTrue(app.element("board").waitForExistence(timeout: 5))
    }

    /// Keeps a picture of the whole screen under this name, as a PNG file without alpha in 8-bit
    /// sRGB, which the App Store requires (research R12). XCUITest waits for the app to go idle
    /// after each action; one more second lets a navigation transition end first.
    @MainActor
    private func capture(_ name: String) {
        _ = XCTWaiter.wait(for: [XCTestExpectation(description: "At rest")], timeout: 1)
        let screen = XCUIScreen.main.screenshot().image
        let format = UIGraphicsImageRendererFormat()
        format.scale = screen.scale
        format.opaque = true
        format.preferredRange = .standard
        let picture = UIGraphicsImageRenderer(size: screen.size, format: format).image { _ in
            screen.draw(at: .zero)
        }
        guard let data = picture.pngData() else {
            XCTFail("The screenshot \(name) could not be encoded")
            return
        }
        let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.png")
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
