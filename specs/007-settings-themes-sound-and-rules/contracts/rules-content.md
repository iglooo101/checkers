# Contract: Rules content

The seven sections of the Rules screen, in order (FR-020, Clarifications), with their pictures
(FR-021) and VoiceOver descriptions (FR-025). Texts are English source strings for the String
Catalog; each section's text is one string. Identifiers are in [screens.md](screens.md).

Pictures are full boards from Light's side (a1 bottom left), built through the engine's public API
(`GameState(position:sideToMove:)`, `apply(_:)`). Marks come from the engine and look as on the
game board with move hints on: in a picture with a selected piece, the piece has its selection
ring, its targets (`targets(from:)`) have dots, and the side to move's other `movablePieces` have
hint rings; a picture without a selected piece has no marks. Nothing is drawn by hand. Tests
rebuild every picture and check what its description claims (research R9).

Word count of the section texts: 364; of the picture descriptions: 156 (*measured* on this
contract; SC-006 allows about 600 for the texts).

## 1. The board (`board`)

**Text**: Checkers is played on the dark squares of an 8 by 8 board. Each side starts with 12 men
on the dark squares of the three rows nearest to it. Light moves first, then the sides take turns.

**Picture**: the starting position (`GameState()`), no marks.
*Description*: "The starting position: 12 Light men on the dark squares of rows 1 to 3, and 12 Dark
men on rows 6 to 8."

## 2. Moving (`moving`)

**Text**: A man moves one square diagonally forward, onto an empty dark square. Tap a piece, then
tap the square it should go to, or drag it there. With move hints on in Settings, the pieces that
can move have a thin ring, and the squares the selected piece can go to have a dot.

**Picture**: the starting position, c3 selected; targets b4, d4; hint rings on a3, e3 and g3.
*Description*: "The Light man on c3 is selected. It can move to b4 or d4. The other men that can
move have a thin ring."
*Checked*: `targets(from: c3) == [b4, d4]`; `movablePieces == [a3, c3, e3, g3]`.

## 3. Capturing (`capturing`)

**Text**: When a man is diagonally next to an opposing piece and the square beyond it is empty, it
can jump over that piece and capture it. Capturing is mandatory: if you can capture, you must.
When there is more than one capture, you choose which one; it does not have to be the longest.

**Picture**: Light men on c3 and g3, a Dark man on d4, Light to move; c3 selected; target e5.
*Description*: "A capture is required. The Light man on c3 must jump the Dark man on d4 and land on
e5. The Light man on g3 cannot move."
*Checked*: a capture is required; `movablePieces == [c3]`; `targets(from: c3) == [e5]`.

## 4. Jumping again (`chains`)

**Text**: After a jump, if the same piece can jump again, it must go on jumping, one jump at a
time. Your turn ends when it cannot jump any further.

**Picture 1**: a Light man on c3, Dark men on d4 and f6, Light to move; c3 selected; target e5.
*Description*: "The Light man on c3 jumps the Dark man on d4 and lands on e5."

**Picture 2**: the same after the step c3–e5: the Light man on e5 selected; target g7.
*Description*: "The Light man now on e5 must jump again, over the Dark man on f6, to g7."
*Checked*: the step c3–e5 continues the turn (`turnContinues`), the chain square is e5, and
`targets(from: e5) == [g7]`.

## 5. Kings (`kings`)

**Text**: A man that reaches the far row is crowned and becomes a king, marked with a crown.
Crowning ends the turn, even in the middle of a chain of jumps. A king moves and captures like a
man, one square at a time, but in all four diagonal directions.

**Picture**: a Light king on d4 and a Dark king on g7, Light to move; d4 selected; targets c5, e5,
c3, e3.
*Description*: "The Light king on d4 is selected. It can move to c5, e5, c3 or e3. A Dark king is
on g7."
*Checked*: `targets(from: d4)` is those four squares.

## 6. Winning and drawing (`ending`)

**Text**: You win when your opponent cannot move: they have no pieces left, or all their pieces are
blocked. You also win when your opponent resigns. The game is a draw when the same position comes
up for the third time with the same side to move, or when both sides have made 40 moves in a row
without a capture or a man moving. There are no draw offers.

**Picture**: a Dark man on h8, Light men on g7 and f6, Dark to move; no marks.
*Description*: "Dark's only man, on h8, is blocked by the Light men on g7 and f6. Dark cannot move,
so Light wins."
*Checked*: Dark has no legal step in that position.

## 7. Undo and resign (`undoResign`)

**Text**: Undo, in the game menu, takes back moves, as far as the start of the game. In a game for
two players it takes back the last turn. Against the computer it takes back your last turn and the
computer's reply. Resign, also in the game menu, ends the game once you confirm. Against the
computer you resign; in a game for two players, the side whose turn it is resigns.

**Illustration**: the game menu's two items, `arrow.uturn.backward` with "Undo" and `flag` with
"Resign" (no board; research R9).
*Description*: "The game menu's Undo and Resign."

## Fidelity (FR-022)

The texts state only rules the engine enforces (E2) and the app's undo and resign behavior (E3,
E4): one-square kings, mandatory but free choice of capture, chains one jump at a time, crowning
ends the turn, loss with no legal move, draws by threefold repetition and by 40 moves per side
without a capture or a man move, no draw offers, undo per turn (two players) or back to the
player's turn (computer), resignation after confirming. A change to any of these rules changes
this text in the same slice.
