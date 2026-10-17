import CheckersEngine
import Testing

struct EngineLinkTests {
    @Test("US4: the app links CheckersEngine")
    func appLinksEngine() {
        #expect(Side.allCases.count == 2)
    }
}
