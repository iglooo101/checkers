import Testing
import UIKit

@testable import checkers

struct PaletteTests {
    @Test("US1 FR-GAME-07: every board color comes from the asset catalog, in light and dark")
    func colorsResolve() {
        for color in Palette.allCases {
            for style in [UIUserInterfaceStyle.light, .dark] {
                let traits = UITraitCollection(userInterfaceStyle: style)
                #expect(
                    UIColor(named: color.rawValue, in: .main, compatibleWith: traits) != nil,
                    "\(color.rawValue) in \(style == .light ? "light" : "dark")")
            }
        }
    }
}
