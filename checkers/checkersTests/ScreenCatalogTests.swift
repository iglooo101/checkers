import Foundation
import Testing

@testable import checkers

struct ScreenCatalogTests {
    @Test("US1: every screen has a bundled HTML file")
    func everyScreenIsBundled() {
        for screen in Screen.all {
            #expect(
                Bundle.main.url(forResource: screen.file, withExtension: "html") != nil,
                "Missing \(screen.file).html"
            )
        }
    }

    @Test("US1: the four screens are listed in order")
    func screensInOrder() {
        #expect(Screen.all.map(\.file) == ["Classic", "Modern", "Playful", "Play"])
    }
}
