import CheckersEngine
import Foundation
import Testing

@testable import checkers

struct US7NavigationTests {
    /// A router showing a two-player game in which c3 is selected.
    static func routerInAGame() -> AppRouter {
        let router = AppRouter(store: InMemorySetupStore())
        router.newGame()
        router.startGame()
        router.session?.tap(Square("c3"))
        return router
    }

    @Test(
        "US7 FR-NAV-04 FR-GAME-06: Rules and Settings open over the game and return to the same game",
        arguments: [Route.rules, .settings])
    func returnToTheSameGame(route: Route) {
        let router = Self.routerInAGame()
        let session = router.session
        let state = session?.state

        router.open(route)
        #expect(router.path == [.game, route])
        router.path.removeLast()

        #expect(router.session === session)
        #expect(router.session?.state == state)
        #expect(router.session?.selection == Square("c3"))
    }

    @Test(
        "US7 FR-NAV-03: leaving a game in progress returns Home at once and keeps it saved (E5 FR-010)"
    )
    func leaveKeepsTheGame() throws {
        let games = InMemorySavedGameStore()
        let router = AppRouter(store: InMemorySetupStore(), games: games)
        router.newGame()
        router.startGame()
        router.session?.tap(Square("c3"))
        router.session?.tap(Square("d4"))
        let state = router.session?.state

        router.requestHome()
        #expect(router.path.isEmpty)
        #expect(router.session == nil)
        #expect(router.hasSavedGame)
        #expect(try games.load()?.state == state)
    }

    @Test(
        "US7 FR-NAV-02: each placeholder screen says what it will contain; Statistics is no longer one"
    )
    func placeholderMessages() {
        #expect(PlaceholderText.message(for: .statistics) == nil)
        #expect(
            PlaceholderText.message(for: .rules)?.key
                == "How to play American checkers will be explained here.")
        #expect(
            PlaceholderText.message(for: .settings)?.key
                == "Board theme, sound effects and move hints will be set here.")
        #expect(PlaceholderText.message(for: .game) == nil)
    }
}
