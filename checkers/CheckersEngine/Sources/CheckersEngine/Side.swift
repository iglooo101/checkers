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
}
