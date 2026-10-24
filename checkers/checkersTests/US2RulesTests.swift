import CheckersEngine
import Foundation
import Testing

@testable import checkers

/// The Rules screen's content (specs/007-settings-themes-sound-and-rules/spec.md, US2): its
/// sections match the contract word for word, and every picture is checked against the engine.
struct US2RulesTests {
    /// One section of contracts/rules-content.md: its id, title, text and picture descriptions.
    struct ContractSection: Equatable {
        let id: String
        let title: String
        let text: String
        let descriptions: [String]
    }

    /// Reads the sections from contracts/rules-content.md, the source of the screen's texts.
    static func contractSections() throws -> [ContractSection] {
        let url = URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "specs/007-settings-themes-sound-and-rules/contracts/rules-content.md")
        let contract = try String(contentsOf: url, encoding: .utf8)
        // Paragraphs, with their lines joined as Markdown renders them.
        let paragraphs = contract.components(separatedBy: "\n\n").map {
            $0.split(separator: "\n").joined(separator: " ")
        }
        var sections: [ContractSection] = []
        var current: (id: String, title: String)?
        var text = ""
        var descriptions: [String] = []
        func finish() {
            if let current {
                sections.append(
                    ContractSection(
                        id: current.id, title: current.title, text: text,
                        descriptions: descriptions))
            }
        }
        for paragraph in paragraphs {
            if let heading = paragraph.firstMatch(of: /^## \d\. (.+) \(`(\w+)`\)$/) {
                finish()
                current = (String(heading.output.2), String(heading.output.1))
                text = ""
                descriptions = []
            } else if paragraph.hasPrefix("## ") {
                finish()
                current = nil
            } else if let match = paragraph.firstMatch(of: /^\*\*Text\*\*: (.+)$/) {
                text = String(match.output.1)
            } else if let match = paragraph.firstMatch(of: /\*Description\*: "(.+?)"/) {
                descriptions.append(String(match.output.1))
            }
        }
        finish()
        return sections
    }

    /// A board picture of a section, with its state and selected piece.
    struct Board {
        let state: GameState
        let selected: Square?
        let picture: RulesPicture
    }

    /// The board pictures of a section.
    static func boards(_ id: String) -> [Board] {
        let section = RulesContent.sections.first { $0.id == id }
        return (section?.pictures ?? []).compactMap { picture in
            guard case .board(let state, let selected, _) = picture else { return nil }
            return Board(state: state, selected: selected, picture: picture)
        }
    }

    @Test("US2 FR-HELP-01: seven sections in order, each title and text as in the contract")
    func sectionsMatchTheContract() throws {
        let contract = try Self.contractSections()
        #expect(
            contract.map(\.id) == [
                "board", "moving", "capturing", "chains", "kings", "ending", "undoResign",
            ])
        #expect(
            RulesContent.sections.map(\.title.key) == [
                "The board", "Moving", "Capturing", "Jumping again", "Kings",
                "Winning and drawing", "Undo and resign",
            ])
        let content = RulesContent.sections.map {
            ContractSection(
                id: $0.id, title: $0.title.key, text: $0.text.key,
                descriptions: $0.pictures.map(\.description.key))
        }
        #expect(content == contract)
    }

    @Test(
        "US2 FR-HELP-01: the six rules sections show boards, the chain two; Undo and resign the menu"
    )
    func picturesPerSection() {
        for section in RulesContent.sections where section.id != "undoResign" {
            #expect(!Self.boards(section.id).isEmpty, "\(section.id)")
            #expect(Self.boards(section.id).count == section.pictures.count, "\(section.id)")
        }
        #expect(Self.boards("chains").count == 2)
        let undoResign = RulesContent.sections.last
        #expect(undoResign?.id == "undoResign")
        #expect(undoResign?.pictures.count == 1)
        guard case .menu = undoResign?.pictures.first else {
            Issue.record("Undo and resign shows no menu picture")
            return
        }
    }

    @Test("US2 FR-HELP-01 FR-AID-01 FR-AID-02: every picture's claim holds in the engine")
    func picturesMatchTheEngine() throws {
        let board = try #require(Self.boards("board").first)
        #expect(board.state == GameState())
        #expect(board.selected == nil)

        let moving = try #require(Self.boards("moving").first)
        #expect(moving.selected == Square("c3"))
        #expect(moving.state.targets(from: Square("c3")) == [Square("b4"), Square("d4")])
        #expect(
            Set(moving.state.movablePieces) == Set(["a3", "c3", "e3", "g3"].map { Square($0) }))

        let capturing = try #require(Self.boards("capturing").first)
        #expect(capturing.state.isCaptureRequired)
        #expect(capturing.state.movablePieces == [Square("c3")])
        #expect(capturing.state.targets(from: Square("c3")) == [Square("e5")])
        #expect(capturing.state.position.piece(at: Square("g3")) == .lightMan)

        let chain = Self.boards("chains")
        try #require(chain.count == 2)
        var first = chain[0].state
        #expect(chain[0].selected == Square("c3"))
        #expect(first.targets(from: Square("c3")) == [Square("e5")])
        let jump = try first.apply(Step("c3", "e5"))
        #expect(jump.turnContinues)
        #expect(first == chain[1].state)
        #expect(chain[1].state.chainSquare == Square("e5"))
        #expect(chain[1].selected == Square("e5"))
        #expect(chain[1].state.targets(from: Square("e5")) == [Square("g7")])

        let kings = try #require(Self.boards("kings").first)
        #expect(kings.state.position.piece(at: Square("d4")) == .lightKing)
        #expect(kings.state.position.piece(at: Square("g7")) == .darkKing)
        #expect(
            Set(kings.state.targets(from: Square("d4")))
                == Set(["c5", "e5", "c3", "e3"].map { Square($0) }))

        let ending = try #require(Self.boards("ending").first)
        #expect(ending.state.sideToMove == .dark)
        #expect(ending.state.legalSteps.isEmpty)
        #expect(ending.selected == nil)
    }

    @Test("US2 FR-AID-01 FR-AID-02: pictures draw the marks as the game does with hints on")
    func picturesDrawTheGamesMarks() {
        for section in RulesContent.sections {
            for board in Self.boards(section.id) {
                let picture = board.picture
                if let selected = board.selected {
                    #expect(
                        picture.targets == Set(board.state.targets(from: selected)),
                        "\(section.id)")
                    #expect(picture.hinted == Set(board.state.movablePieces), "\(section.id)")
                } else {
                    #expect(picture.targets.isEmpty && picture.hinted.isEmpty, "\(section.id)")
                }
            }
        }
        let moving = Self.boards("moving").first?.picture
        #expect(moving?.hinted == Set(["a3", "c3", "e3", "g3"].map { Square($0) }))
    }

    @Test("US2 SC-006: the section texts are at most 600 words")
    func wordCount() {
        let words = RulesContent.sections.map {
            $0.text.key.split(whereSeparator: \.isWhitespace).count
        }
        #expect(words.reduce(0, +) <= 600)
    }
}
