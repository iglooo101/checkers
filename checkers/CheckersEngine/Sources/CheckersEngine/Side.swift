/// One of the two sides in a game. Light moves first (FRD glossary).
public enum Side: Sendable, CaseIterable {
    case light
    case dark

    /// The side playing against this one.
    public var opponent: Side {
        switch self {
        case .light: .dark
        case .dark: .light
        }
    }

    /// The two directions this side's men move and capture in: toward row 8 for Light, toward
    /// row 1 for Dark (FR-004).
    var forwardDirections: [Direction] {
        switch self {
        case .light: [.northwest, .northeast]
        case .dark: [.southwest, .southeast]
        }
    }

    /// The zero-based row where this side's men are crowned: row 8 for Light, row 1 for Dark
    /// (FR-012).
    var farRow: Int {
        switch self {
        case .light: 7
        case .dark: 0
        }
    }
}
