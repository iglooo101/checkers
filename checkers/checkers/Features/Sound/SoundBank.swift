import AVFoundation

/// Why a sound could not play (specs/007-settings-themes-sound-and-rules/contracts/
/// settings-and-sound.md, "When sounds cannot play").
nonisolated enum SoundError: Error, Equatable, Sendable {
    /// The bundle has no file for the sound.
    case missingFile(SoundEffect)
    /// The sound's file does not load as audio.
    case unreadableFile(SoundEffect)
    /// The audio session's category cannot be set.
    case audioSession
    /// A prepared player did not start.
    case playback(SoundEffect)
}

/// The audio session and one prepared player per sound, off the main actor: loading the players
/// and starting one both take long enough to cause hitches there (research R7).
actor SoundBank {
    /// Muted by the silent switch, follows the volume buttons, mixes with other apps' audio and
    /// needs no permission (FR-016, FR-024).
    static let category = AVAudioSession.Category.ambient

    private let directory: URL
    private var players: [SoundEffect: AVAudioPlayer] = [:]

    /// A bank for the four sound files in `directory`.
    init(directory: URL) {
        self.directory = directory
    }

    /// Whether the four players are ready.
    var isPrepared: Bool {
        players.count == SoundEffect.allCases.count
    }

    /// Sets the audio session's category and loads the four players; after a failure the bank
    /// stays unprepared, so the next sound prepares it again.
    func prepare() throws(SoundError) {
        players = [:]
        do {
            try AVAudioSession.sharedInstance().setCategory(Self.category)
        } catch {
            throw .audioSession
        }
        var loaded: [SoundEffect: AVAudioPlayer] = [:]
        for effect in SoundEffect.allCases {
            let url = directory.appending(path: effect.fileName)
            guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else {
                throw .missingFile(effect)
            }
            let player: AVAudioPlayer
            do {
                player = try AVAudioPlayer(contentsOf: url)
            } catch {
                throw .unreadableFile(effect)
            }
            player.prepareToPlay()
            loaded[effect] = player
        }
        players = loaded
    }

    /// Plays a sound from its start, preparing the bank first if it is not ready. Each sound has
    /// its own player, so a sound starts even while another still plays (FR-019).
    func play(_ effect: SoundEffect) throws(SoundError) {
        if !isPrepared {
            try prepare()
        }
        guard let player = players[effect] else { throw .missingFile(effect) }
        player.currentTime = 0
        guard player.play() else {
            players = [:]
            throw .playback(effect)
        }
    }

    /// The system has reset its media services, so the players no longer work; the next sound
    /// prepares new ones.
    func mediaServicesWereReset() {
        players = [:]
    }
}
