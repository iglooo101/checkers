import AVFoundation
import Foundation
import OSLog
import Observation

/// Plays the game's sounds (FR-014). Injected so tests and previews never play audio
/// (Constitution II.3, workflow gate 4).
protocol SoundPlayer: AnyObject {
    /// Plays a sound and returns at once; a failure never reaches the caller.
    func play(_ effect: SoundEffect)
    /// Whether sounds can play: true at first and after a sound or a preparation succeeds, false
    /// after one fails (FR-017, FR-SND-05). Observed by Settings.
    var isAvailable: Bool { get }
}

/// Plays the sounds through a `SoundBank`, off the main actor; it starts preparing the bank when
/// created, right after launch (research R7).
@Observable
final class AudioSoundPlayer: SoundPlayer {
    private(set) var isAvailable = true

    @ObservationIgnored private let bank: SoundBank
    /// Tells the bank when the system resets its media services.
    @ObservationIgnored private let resets: Task<Void, Never>

    init(bank: SoundBank = SoundBank(directory: Bundle.main.resourceURL ?? Bundle.main.bundleURL)) {
        self.bank = bank
        resets = Task { [bank] in
            let name = AVAudioSession.mediaServicesWereResetNotification
            for await _ in NotificationCenter.default.notifications(named: name) {
                await bank.mediaServicesWereReset()
            }
        }
        Task { [weak self, bank] in
            do throws(SoundError) {
                try await bank.prepare()
                self?.isAvailable = true
            } catch {
                self?.failed(error)
            }
        }
    }

    deinit {
        resets.cancel()
    }

    func play(_ effect: SoundEffect) {
        Task { [weak self, bank] in
            do throws(SoundError) {
                try await bank.play(effect)
                self?.isAvailable = true
            } catch {
                self?.failed(error)
            }
        }
    }

    /// The game goes on without the sound; Settings says so while sounds cannot play.
    private func failed(_ error: SoundError) {
        Log.sound.error("A sound could not play: \(String(describing: error), privacy: .public)")
        isAvailable = false
    }
}

/// Keeps the sounds it is asked to play, in order, and plays nothing: for tests and previews.
@Observable
final class RecordingSoundPlayer: SoundPlayer {
    private(set) var played: [SoundEffect] = []
    var isAvailable: Bool

    init(isAvailable: Bool = true) {
        self.isAvailable = isAvailable
    }

    func play(_ effect: SoundEffect) {
        played.append(effect)
    }
}
