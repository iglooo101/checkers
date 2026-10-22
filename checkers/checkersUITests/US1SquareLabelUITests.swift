import XCTest

final class US1SquareLabelUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// FR-A11Y-01: square labels state coordinate, contents and state in the running app.
    @MainActor
    func testUS1_squareDescriptions() {
        let app = XCUIApplication()
        app.launch()
        app.startTwoPlayerGame()
        XCTAssertEqual(app.square("c3").label, "c3, Light man, can move")
        XCTAssertEqual(app.square("c1").label, "c1, Light man")
        XCTAssertEqual(app.square("d4").label, "d4, empty")

        app.square("c3").tap()
        XCTAssertEqual(app.square("c3").label, "c3, Light man, selected")
        XCTAssertEqual(app.square("d4").label, "d4, empty, legal target")
    }

    /// FR-A11Y-01 (FR-003): VoiceOver visits the dark squares in on-screen order, row by row from
    /// the top, left to right, and skips the light squares.
    @MainActor
    func testUS1_readingOrder() {
        let app = XCUIApplication()
        app.launch()
        app.startTwoPlayerGame()
        let squares = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'square.'"))
            .allElementsBoundByIndex.map { String($0.identifier.dropFirst("square.".count)) }
        let expected = (1...8).reversed().flatMap { row in
            "abcdefgh".enumerated().compactMap { column, letter in
                (column + row - 1).isMultiple(of: 2) ? "\(letter)\(row)" : nil
            }
        }
        XCTAssertEqual(squares, expected)
    }
}
