import XCTest

final class AppSmokeUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testUS1_launchShowsFourScreens() {
        let app = XCUIApplication()
        app.launch()

        for title in ["Classic", "Modern", "Playful", "Play"] {
            XCTAssertTrue(app.buttons[title].waitForExistence(timeout: 10), "Missing tab \(title)")
        }
    }

    /// Guards FR-021: the existing Play screen still accepts a move.
    @MainActor
    func testUS1_playScreenAcceptsAMove() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["Play"].tap()

        let webView = app.webViews.firstMatch
        XCTAssertTrue(webView.staticTexts["Light to move"].waitForExistence(timeout: 10))
        let newGame = webView.buttons["New game"]
        XCTAssertTrue(newGame.waitForExistence(timeout: 10))

        let board = PlayBoard(webViewFrame: webView.frame, newGameButtonFrame: newGame.frame)
        tap(board.center(row: 5, column: 0), in: app)
        tap(board.center(row: 4, column: 1), in: app)

        XCTAssertTrue(webView.staticTexts["Dark to move"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func tap(_ point: CGPoint, in app: XCUIApplication) {
        app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: point.x, dy: point.y))
            .tap()
    }
}

/// Geometry of the board in `Play.html`: the cell size follows its `--cell` CSS rule, and the
/// board's inner bottom edge sits 22 points (12 margin + 10 border) above the New game button.
private struct PlayBoard {
    let cell: CGFloat
    let left: CGFloat
    let bottom: CGFloat

    init(webViewFrame: CGRect, newGameButtonFrame: CGRect) {
        cell = min(
            (webViewFrame.width - 60) / 8,
            (webViewFrame.height - 220) / 8,
            60
        )
        left = webViewFrame.midX - 4 * cell
        bottom = newGameButtonFrame.minY - 22
    }

    func center(row: Int, column: Int) -> CGPoint {
        CGPoint(
            x: left + (CGFloat(column) + 0.5) * cell,
            y: bottom - (CGFloat(7 - row) + 0.5) * cell
        )
    }
}
