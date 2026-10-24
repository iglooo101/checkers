import Testing
import UIKit

@testable import checkers

struct PaletteTests {
    @Test(
        "US3 FR-GAME-07: every board color of every theme comes from the asset catalog, in light and dark"
    )
    func colorsResolve() {
        for theme in BoardTheme.allCases {
            for color in Palette.allCases {
                for style in [UIUserInterfaceStyle.light, .dark] {
                    let traits = UITraitCollection(userInterfaceStyle: style)
                    #expect(
                        UIColor(
                            named: color.assetName(in: theme), in: .main, compatibleWith: traits)
                            != nil,
                        "\(color.assetName(in: theme)) in \(style == .light ? "light" : "dark")")
                }
            }
        }
    }
}
