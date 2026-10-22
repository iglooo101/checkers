import Foundation

/// Whether Rules or Settings covers the game screen, and a way to wait until the game is visible
/// again: the computer's next step waits behind it (FR-NAV-04;
/// specs/005-computer-opponent/contracts/computer-turn.md, Timeline).
final class ScreenCover {
    private(set) var isCovered = false
    /// The tasks waiting for the game to be visible again.
    private var waiters: [UUID: CheckedContinuation<Void, Never>] = [:]

    /// Covers or uncovers the game; uncovering lets every waiting task go.
    func set(_ covered: Bool) {
        isCovered = covered
        guard !covered else { return }
        let released = waiters.values
        waiters.removeAll()
        for waiter in released {
            waiter.resume()
        }
    }

    /// Returns once the game is visible: at once if it is, or when it is uncovered or the task is
    /// cancelled.
    func untilVisible() async {
        let id = UUID()
        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                if isCovered, !Task.isCancelled {
                    waiters[id] = continuation
                } else {
                    continuation.resume()
                }
            }
        } onCancel: {
            Task { @MainActor in self.release(id) }
        }
    }

    private func release(_ id: UUID) {
        waiters.removeValue(forKey: id)?.resume()
    }
}
