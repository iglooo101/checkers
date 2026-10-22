import CheckersEngine
import Foundation
import Testing

@testable import checkers

/// The two seams the computer's turn runs through: who chooses its turn and how it pauses
/// (specs/005-computer-opponent/research.md R8).
struct ComputerSeamTests {
    @Test("A scripted opponent answers with its turns in order")
    func scriptedTurnsInOrder() async {
        let opponent = ScriptedComputerOpponent(turns: [[Step("f6", "e5")], [Step("b6", "a5")]])
        #expect(await opponent.chooseTurn(in: GameState(), difficulty: .easy) == [Step("f6", "e5")])
        #expect(await opponent.chooseTurn(in: GameState(), difficulty: .easy) == [Step("b6", "a5")])
        #expect(opponent.requests == 2)
    }

    @Test("A scripted opponent with no turns left waits until cancelled, then answers nil")
    func scriptedWaitsUntilCancelled() async {
        let opponent = ScriptedComputerOpponent()
        let task = Task { await opponent.chooseTurn(in: GameState(), difficulty: .easy) }
        await waitUntil { opponent.requests == 1 }
        await settle()
        task.cancel()
        #expect(await task.value == nil)
    }

    @Test("A held scripted opponent answers only when released")
    func scriptedHeldUntilReleased() async {
        let opponent = ScriptedComputerOpponent(turns: [[Step("f6", "e5")]], isHeld: true)
        var answer: [Step]?
        let task = Task { answer = await opponent.chooseTurn(in: GameState(), difficulty: .easy) }
        await waitUntil { opponent.requests == 1 }
        await settle()
        #expect(answer == nil)
        opponent.release()
        await task.value
        #expect(answer == [Step("f6", "e5")])
    }

    @Test("A manual pacer records each pause and resumes only when told to")
    func manualPacer() async throws {
        let pacer = ManualPacer()
        var resumed = false
        let task = Task {
            try await pacer.pause(.milliseconds(500))
            resumed = true
        }
        await waitUntil { pacer.waiting == 1 }
        await settle()
        #expect(!resumed)
        #expect(pacer.requested == [.milliseconds(500)])
        pacer.resumeNext()
        try await task.value
        #expect(resumed)
    }

    @Test("A cancelled pause throws CancellationError, with the manual and the sleeping pacer")
    func cancelledPauses() async {
        let pacer = ManualPacer()
        let manual = Task { try await pacer.pause(.milliseconds(500)) }
        await waitUntil { pacer.waiting == 1 }
        manual.cancel()
        await #expect(throws: CancellationError.self) { try await manual.value }

        let sleeping = Task { try await SleepingPacer().pause(.seconds(30)) }
        sleeping.cancel()
        await #expect(throws: CancellationError.self) { try await sleeping.value }
    }
}
