import Testing

@testable import CheckersEngine

struct StepTests {
    @Test("A one-square diagonal step is a simple move")
    func simpleMove() {
        let step = Step(from: Square("c3"), to: Square("d4"))
        #expect(!step.isJump)
        #expect(step.captured == nil)
    }

    @Test(
        "A two-square diagonal step is a jump over the square in between",
        arguments: [("c3", "e5", "d4"), ("e5", "c3", "d4"), ("a1", "c3", "b2"), ("f6", "h4", "g5")]
    )
    func jump(from: String, to: String, captured: String) {
        let step = Step(from: Square(from), to: Square(to))
        #expect(step.isJump)
        #expect(step.captured == Square(captured))
    }

    @Test(
        "Steps that are not one or two diagonal squares long capture nothing",
        arguments: [("c3", "c5"), ("c3", "f6"), ("c3", "c3"), ("a1", "c1")]
    )
    func notAJump(from: String, to: String) {
        let step = Step(from: Square(from), to: Square(to))
        #expect(!step.isJump)
        #expect(step.captured == nil)
    }
}
