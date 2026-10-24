import CheckersEngine
import Foundation
import OSLog

/// A picture of a Rules section (specs/007-settings-themes-sound-and-rules/contracts/
/// rules-content.md): a board position or the game menu's Undo and Resign items.
enum RulesPicture {
    /// A position from Light's side. With a selected piece, its marks are drawn as on the game
    /// board with move hints on; without one, there are none.
    case board(state: GameState, selected: Square?, description: LocalizedStringResource)
    /// The game menu's Undo and Resign items.
    case menu

    /// What VoiceOver says about the picture (FR-025).
    var description: LocalizedStringResource {
        switch self {
        case .board(_, _, let description): return description
        case .menu: return "The game menu's Undo and Resign."
        }
    }

    /// The squares with a target dot: the selected piece's legal targets (FR-AID-02).
    var targets: Set<Square> {
        guard case .board(let state, let selected?, _) = self else { return [] }
        return Set(state.targets(from: selected))
    }

    /// The pieces with a hint ring while one is selected: every movable piece of the side to
    /// move; the selected one shows its selection ring instead (FR-AID-01).
    var hinted: Set<Square> {
        guard case .board(let state, .some, _) = self else { return [] }
        return Set(state.movablePieces)
    }
}

/// One section of the Rules screen: a heading, its text and its pictures (FR-020, FR-021).
struct RulesSection: Identifiable {
    /// Names the section's identifiers, such as `rules.board.title`.
    let id: String
    let title: LocalizedStringResource
    let text: LocalizedStringResource
    let pictures: [RulesPicture]
}

/// The Rules screen's seven sections, in order (FR-HELP-01). Every position is built through the
/// engine and every mark comes from it, so a picture cannot contradict the rules (research R9).
enum RulesContent {
    static let sections: [RulesSection] = [
        RulesSection(
            id: "board", title: "The board",
            text:
                "Checkers is played on the dark squares of an 8 by 8 board. Each side starts with 12 men on the dark squares of the three rows nearest to it. Light moves first, then the sides take turns.",
            pictures: [
                .board(
                    state: GameState(), selected: nil,
                    description:
                        "The starting position: 12 Light men on the dark squares of rows 1 to 3, and 12 Dark men on rows 6 to 8."
                )
            ]),
        RulesSection(
            id: "moving", title: "Moving",
            text:
                "A man moves one square diagonally forward, onto an empty dark square. Tap a piece, then tap the square it should go to, or drag it there. With move hints on in Settings, the pieces that can move have a thin ring, and the squares the selected piece can go to have a dot.",
            pictures: [
                .board(
                    state: GameState(), selected: square("c3"),
                    description:
                        "The Light man on c3 is selected. It can move to b4 or d4. The other men that can move have a thin ring."
                )
            ]),
        RulesSection(
            id: "capturing", title: "Capturing",
            text:
                "When a man is diagonally next to an opposing piece and the square beyond it is empty, it can jump over that piece and capture it. Capturing is mandatory: if you can capture, you must. When there is more than one capture, you choose which one; it does not have to be the longest.",
            pictures: [
                .board(
                    state: state(
                        ["c3": .lightMan, "g3": .lightMan, "d4": .darkMan], toMove: .light),
                    selected: square("c3"),
                    description:
                        "A capture is required. The Light man on c3 must jump the Dark man on d4 and land on e5. The Light man on g3 cannot move."
                )
            ]),
        RulesSection(
            id: "chains", title: "Jumping again",
            text:
                "After a jump, if the same piece can jump again, it must go on jumping, one jump at a time. Your turn ends when it cannot jump any further.",
            pictures: [
                .board(
                    state: chainStart, selected: square("c3"),
                    description: "The Light man on c3 jumps the Dark man on d4 and lands on e5."),
                .board(
                    state: after(from: "c3", to: "e5", in: chainStart), selected: square("e5"),
                    description:
                        "The Light man now on e5 must jump again, over the Dark man on f6, to g7."),
            ]),
        RulesSection(
            id: "kings", title: "Kings",
            text:
                "A man that reaches the far row is crowned and becomes a king, marked with a crown. Crowning ends the turn, even in the middle of a chain of jumps. A king moves and captures like a man, one square at a time, but in all four diagonal directions.",
            pictures: [
                .board(
                    state: state(["d4": .lightKing, "g7": .darkKing], toMove: .light),
                    selected: square("d4"),
                    description:
                        "The Light king on d4 is selected. It can move to c5, e5, c3 or e3. A Dark king is on g7."
                )
            ]),
        RulesSection(
            id: "ending", title: "Winning and drawing",
            text:
                "You win when your opponent cannot move: they have no pieces left, or all their pieces are blocked. You also win when your opponent resigns. The game is a draw when the same position comes up for the third time with the same side to move, or when both sides have made 40 moves in a row without a capture or a man moving. There are no draw offers.",
            pictures: [
                .board(
                    state: state(
                        ["h8": .darkMan, "g7": .lightMan, "f6": .lightMan], toMove: .dark),
                    selected: nil,
                    description:
                        "Dark's only man, on h8, is blocked by the Light men on g7 and f6. Dark cannot move, so Light wins."
                )
            ]),
        RulesSection(
            id: "undoResign", title: "Undo and resign",
            text:
                "Undo, in the game menu, takes back moves, as far as the start of the game. In a game for two players it takes back the last turn. Against the computer it takes back your last turn and the computer's reply. Resign, also in the game menu, ends the game once you confirm. Against the computer you resign; in a game for two players, the side whose turn it is resigns.",
            pictures: [.menu]),
    ]

    /// A Light man on c3, Dark men on d4 and f6, Light to move: a chain of two jumps.
    private static let chainStart = state(
        ["c3": .lightMan, "d4": .darkMan, "f6": .darkMan], toMove: .light)

    /// The square with this name; the names here are all dark squares.
    private static func square(_ name: String) -> Square? {
        Square(name: name)
    }

    /// A position from square names, with the side to move.
    private static func state(_ layout: [String: Piece], toMove side: Side) -> GameState {
        let pieces = Dictionary(
            uniqueKeysWithValues: layout.compactMap { name, piece in
                Square(name: name).map { ($0, piece) }
            })
        return GameState(position: Position(pieces), sideToMove: side)
    }

    /// The state after one step, played through the engine.
    private static func after(from: String, to: String, in start: GameState) -> GameState {
        var state = start
        guard let from = Square(name: from), let to = Square(name: to) else { return state }
        do {
            _ = try state.apply(Step(from: from, to: to))
        } catch {
            Log.app.error("A Rules picture's step was rejected: \(String(describing: error))")
        }
        return state
    }
}

extension Piece {
    /// The four kinds of piece, for the Rules positions.
    fileprivate static let lightMan = Piece(side: .light, kind: .man)
    fileprivate static let lightKing = Piece(side: .light, kind: .king)
    fileprivate static let darkMan = Piece(side: .dark, kind: .man)
    fileprivate static let darkKing = Piece(side: .dark, kind: .king)
}
