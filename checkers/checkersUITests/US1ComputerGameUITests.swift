import XCTest

/// Playing the computer in the running app (specs/005-computer-opponent/spec.md, US1). The app
/// seeds the computer at random, so these tests check what any reply must look like.
final class US1ComputerGameUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// FR-AI-01, FR-AI-03: after the player's move one of Dark's front men moves and it is Light's
    /// turn again. The thinking sentence lasts about half a second, less than XCUITest needs to
    /// see it after a tap, so it is tested in `US1ComputerGameTests` and the previews.
    @MainActor
    func testUS1_computerReplies() {
        let app = XCUIApplication()
        app.launch()
        app.startComputerGame(difficulty: "Easy", side: "Light")
        app.waitForTurn(startingWith: "Light to move")
        app.move("c3", "d4")
        app.waitForTurn(startingWith: "Light to move")
        let frontRow = ["b6", "d6", "f6", "h6"].filter {
            app.square($0).label.contains("Dark man")
        }
        XCTAssertEqual(frontRow.count, 3, "Exactly one of Dark's front men should have moved")
    }

    /// FR-AI-06, FR-GAME-03: with the player as Dark, the computer opens as Light without any
    /// input, and the player's pieces are at the bottom.
    @MainActor
    func testUS1_computerOpensAsLight() {
        let app = XCUIApplication()
        app.launch()
        app.startComputerGame(difficulty: "Easy", side: "Dark")
        app.waitForTurn(startingWith: "Dark to move")
        let frontRow = ["a3", "c3", "e3", "g3"].filter {
            app.square($0).label.contains("Light man")
        }
        XCTAssertEqual(frontRow.count, 3, "Exactly one of Light's front men should have moved")
        XCTAssertGreaterThan(
            app.square("b6").frame.minY, app.square("a3").frame.minY,
            "Dark's pieces should be at the bottom")
    }
}
