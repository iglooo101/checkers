/// Waits between the moments of the computer's turn: its minimum thinking pause and the pause
/// before each further jump (FR-008, FR-009). Injected so tests control time (Constitution II.3;
/// specs/005-computer-opponent/research.md R8).
protocol TurnPacer {
    /// Waits for `duration`; throws `CancellationError` if the task is cancelled meanwhile.
    func pause(_ duration: Duration) async throws
}

/// Waits for real time.
struct SleepingPacer: TurnPacer {
    func pause(_ duration: Duration) async throws {
        try await Task.sleep(for: duration)
    }
}
