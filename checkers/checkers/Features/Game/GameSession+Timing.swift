import OSLog

/// The computer's timing, measured on the phone (specs/008-release-1-0/contracts/
/// release-tooling.md, "Device logs"): one line per computer turn, which
/// `scripts/device-timings.py` reads. It changes nothing in the game (FR-031).
extension GameSession {
    /// Logs how long after its turn started the computer's first step appeared.
    func logFirstComputerStep(since start: ContinuousClock.Instant, difficulty: Difficulty) {
        let (seconds, attoseconds) = (ContinuousClock.now - start).components
        let milliseconds = seconds * 1_000 + attoseconds / 1_000_000_000_000_000
        Log.computer.notice(
            "Computer turn at \(difficulty.rawValue, privacy: .public): first step after \(milliseconds, privacy: .public) ms"
        )
    }
}
