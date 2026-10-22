import Foundation
import Testing

@testable import checkers

/// A pacer for tests: it records every pause the computer's turn asks for and holds each one
/// until the test calls `resumeNext()`, so timing is tested without waiting (research R8).
final class ManualPacer: TurnPacer {
    /// Every requested pause, in order.
    private(set) var requested: [Duration] = []
    private var pending: [(id: UUID, continuation: CheckedContinuation<Void, any Error>)] = []

    /// How many pauses are waiting to be resumed.
    var waiting: Int {
        pending.count
    }

    func pause(_ duration: Duration) async throws {
        requested.append(duration)
        try Task.checkCancellation()
        let id = UUID()
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                pending.append((id, continuation))
            }
        } onCancel: {
            Task { @MainActor in self.cancel(id) }
        }
    }

    /// Ends the oldest waiting pause.
    func resumeNext() {
        guard !pending.isEmpty else { return }
        pending.removeFirst().continuation.resume()
    }

    private func cancel(_ id: UUID) {
        guard let index = pending.firstIndex(where: { $0.id == id }) else { return }
        pending.remove(at: index).continuation.resume(throwing: CancellationError())
    }
}

/// Lets other main-actor work run until `condition` holds, failing the test if it never does.
func waitUntil(
    _ condition: () -> Bool, sourceLocation: SourceLocation = #_sourceLocation
) async {
    for _ in 0..<10_000 {
        if condition() { return }
        await Task.yield()
    }
    Issue.record("The condition never held", sourceLocation: sourceLocation)
}

/// Lets pending main-actor work run, so a test can check that something did not happen.
func settle() async {
    for _ in 0..<100 {
        await Task.yield()
    }
}
