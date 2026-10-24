import SwiftUI

/// The result shown over the final position once a game ends, with Play again and Home
/// (FR-033). The board stays visible around it; the panel itself is opaque so its text and
/// buttons keep their contrast (specs/004-accessibility research R6).
struct ResultPanel: View {
    let text: LocalizedStringResource
    let playAgain: () -> Void
    let home: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(text)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("result.text")
                Button(action: playAgain) {
                    Text("Play again")
                        .foregroundStyle(Color.onAccent)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("result.playAgain")
                Button(action: home) {
                    Text("Home").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("result.home")
            }
            .controlSize(.large)
            .padding(24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .fixedSize(horizontal: false, vertical: true)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .padding(24)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("result.panel")
    }
}

#Preview("Every result") {
    ScrollView {
        VStack {
            ForEach(
                [
                    "Light wins: no moves left", "Dark wins: no moves left", "Light resigned",
                    "Dark resigned", "Draw by repetition", "Draw by no progress",
                ] as [LocalizedStringResource], id: \.key
            ) { text in
                ResultPanel(text: text, playAgain: {}, home: {})
            }
        }
    }
    .background(Palette.boardDarkSquare.color(in: .classic))
}

#Preview("Large text, dark") {
    ResultPanel(text: "Dark wins: no moves left", playAgain: {}, home: {})
        .background(Palette.boardDarkSquare.color(in: .classic))
        .environment(\.dynamicTypeSize, .accessibility5)
        .preferredColorScheme(.dark)
}
