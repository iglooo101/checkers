import AVFoundation
import Foundation
import Testing

@testable import checkers

/// The sounds' files, the bank that plays them and what happens when they cannot play
/// (specs/007-settings-themes-sound-and-rules/spec.md, US4; contracts/settings-and-sound.md,
/// "Playback" and "When sounds cannot play").
struct US4SoundPlaybackTests {
    /// Waits up to `seconds` for work off the main actor, such as the sound bank's preparation.
    static func waitFor(_ condition: () -> Bool, seconds: Double = 5) async throws {
        let deadline = ContinuousClock.now + .seconds(seconds)
        while !condition() && ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(10))
        }
    }

    @Test(
        "US4 FR-SND-02: sounds use the ambient audio session, which follows silent mode and volume")
    func ambientCategory() {
        #expect(SoundBank.category == .ambient)
    }

    @Test("US4 FR-SND-01: the four sounds are in the app and load; each is short enough")
    func bundledSounds() throws {
        for effect in SoundEffect.allCases {
            let url = try #require(
                Bundle.main.url(forResource: effect.rawValue, withExtension: "wav"), "\(effect)")
            #expect(url.lastPathComponent == effect.fileName)
            let player = try AVAudioPlayer(contentsOf: url)
            let limit = effect == .gameEnd ? 2.0 : 0.5
            #expect(
                player.duration > 0 && player.duration <= limit, "\(effect): \(player.duration)")
        }
    }

    /// A temporary copy of the app's sounds without some of them, or with one damaged.
    static func soundDirectory(
        without missing: Set<SoundEffect> = [], damaging damaged: SoundEffect? = nil
    ) throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appending(
            path: "US4SoundTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for effect in SoundEffect.allCases where !missing.contains(effect) {
            let target = directory.appending(path: effect.fileName)
            if effect == damaged {
                try Data("not a sound".utf8).write(to: target)
            } else {
                let source = try #require(
                    Bundle.main.url(forResource: effect.rawValue, withExtension: "wav"))
                try FileManager.default.copyItem(at: source, to: target)
            }
        }
        return directory
    }

    @Test("US4 FR-SND-05: a bank missing a file or with a damaged one stays unprepared until fixed")
    func bankFailures() async throws {
        let missing = try Self.soundDirectory(without: [.capture])
        let damaged = try Self.soundDirectory(damaging: .move)
        defer {
            for directory in [missing, damaged] {
                try? FileManager.default.removeItem(at: directory)
            }
        }
        let bank = SoundBank(directory: missing)
        await #expect(throws: SoundError.missingFile(.capture)) { try await bank.prepare() }
        #expect(await !bank.isPrepared)
        let damagedBank = SoundBank(directory: damaged)
        await #expect(throws: SoundError.unreadableFile(.move)) { try await damagedBank.prepare() }
        #expect(await !damagedBank.isPrepared)

        let capture = try #require(Bundle.main.url(forResource: "capture", withExtension: "wav"))
        try FileManager.default.copyItem(at: capture, to: missing.appending(path: "capture.wav"))
        try await bank.prepare()
        #expect(await bank.isPrepared)
        await bank.mediaServicesWereReset()
        #expect(await !bank.isPrepared, "a reset discards the players")
    }

    @Test("US4 FR-SND-05: a player whose sounds cannot be prepared says they are unavailable")
    func playerReportsUnavailable() async throws {
        let missing = try Self.soundDirectory(without: [.capture])
        defer { try? FileManager.default.removeItem(at: missing) }
        let player = AudioSoundPlayer(bank: SoundBank(directory: missing))
        try await Self.waitFor { !player.isAvailable }
        #expect(!player.isAvailable)
    }

    @Test("US4 FR-SND-05: Settings' notice shows while sound effects are on and cannot play")
    func soundNotice() {
        let sounds = RecordingSoundPlayer()
        let router = AppRouter(store: InMemorySetupStore(), sounds: sounds)
        #expect(!router.showsSoundNotice)
        sounds.isAvailable = false
        #expect(router.showsSoundNotice)
        router.settings.soundEffects = false
        #expect(!router.showsSoundNotice)
        router.settings.soundEffects = true
        #expect(router.showsSoundNotice)
        sounds.isAvailable = true
        #expect(!router.showsSoundNotice)
    }
}
