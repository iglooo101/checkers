/// The game's sounds (specs/007-settings-themes-sound-and-rules/contracts/settings-and-sound.md,
/// "Which sound").
extension GameSession {
    /// Plays a sound while sound effects are on (E6 FR-014, FR-017); with them off, nothing plays.
    func playSound(_ effect: SoundEffect) {
        guard settings.soundEffects else { return }
        sounds.play(effect)
    }
}
