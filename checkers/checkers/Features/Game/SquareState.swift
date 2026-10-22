/// What VoiceOver says a square can do, after its coordinate and contents (FR-A11Y-01). It never
/// depends on the move hints setting (specs/004-accessibility, Clarifications).
enum SquareState: Equatable {
    case none
    /// A movable piece of the side to move.
    case canMove
    /// The selected piece.
    case selected
    /// An empty square the selected piece can move to.
    case legalTarget
}
