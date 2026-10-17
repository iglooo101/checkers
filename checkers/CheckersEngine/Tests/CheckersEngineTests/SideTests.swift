import Testing

@testable import CheckersEngine

struct SideTests {
    @Test("US4: each side's opponent is the other side")
    func opponent() {
        #expect(Side.light.opponent == .dark)
        #expect(Side.dark.opponent == .light)
    }
}
