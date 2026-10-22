import CheckersEngine
import Foundation
import Testing

@testable import checkers

struct US6SetupTests {
    static let computer = GameSetup(opponent: .computer, difficulty: .hard, side: .dark)

    /// A private defaults suite for one test, removed afterwards.
    static func withDefaults(_ body: (UserDefaults) -> Void) {
        let name = "US6SetupTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        body(defaults)
    }

    @Test("US6 FR-SETUP-03: first use is Two players, Easy, Light, and choices survive encoding")
    func defaultsAndEncoding() throws {
        #expect(
            GameSetup.defaults == GameSetup(opponent: .twoPlayers, difficulty: .easy, side: .light))
        let data = try JSONEncoder().encode(Self.computer)
        #expect(try JSONDecoder().decode(GameSetup.self, from: data) == Self.computer)
    }

    @Test(
        "US6 FR-SETUP-03: the defaults store remembers the last choices and falls back to the defaults"
    )
    func userDefaultsStore() {
        Self.withDefaults { defaults in
            let store = UserDefaultsSetupStore(defaults: defaults)
            #expect(store.load() == .defaults)
            store.save(Self.computer)
            #expect(UserDefaultsSetupStore(defaults: defaults).load() == Self.computer)
            defaults.set(Data("not a setup".utf8), forKey: "lastGameSetup")
            #expect(store.load() == .defaults)
        }
    }

    @Test("US6 FR-SETUP-02 FR-SETUP-03: every change in setup is remembered at once")
    func choicesSavedOnChange() {
        let store = InMemorySetupStore()
        let router = AppRouter(store: store)
        router.newGame()
        router.setup.opponent = .computer
        #expect(store.load().opponent == .computer)
        router.setup.difficulty = .medium
        #expect(store.load().difficulty == .medium)
        router.setup.side = .random
        #expect(store.load().side == .random)
    }

    @Test("US6 FR-GAME-03: against the computer the player's pieces are at the bottom")
    func playerAtTheBottom() {
        #expect(GameSession(setup: Self.computer, playerSide: .dark).layout.bottomSide == .dark)
        #expect(GameSession(setup: Self.computer, playerSide: .light).layout.bottomSide == .light)
    }

    @Test("US6 FR-END-02: against the computer the player resigns, whoever is to move")
    func playerResigns() {
        let session = GameSession(setup: Self.computer, playerSide: .dark)
        #expect(session.state.sideToMove == .light)
        #expect(session.resigningSide == .dark)
    }

    @Test("US6 FR-END-07: Play again draws a Random side again and keeps a fixed one")
    func randomSideRedrawn() {
        var draws: [Side] = [.dark, .light, .dark]
        let router = AppRouter(store: InMemorySetupStore(), drawSide: { draws.removeFirst() })
        var random = Self.computer
        random.side = .random

        router.open(gameWith: random)
        #expect(router.session?.playerSide == .dark)
        router.playAgain()
        #expect(router.session?.playerSide == .light)
        router.playAgain()
        #expect(router.session?.playerSide == .dark)

        router.open(gameWith: Self.computer)
        router.playAgain()
        #expect(router.session?.playerSide == .dark)
        #expect(draws.isEmpty)
    }
}
