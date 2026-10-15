import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let htmlFileName: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.contentInsetAdjustmentBehavior = .automatic
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url = Bundle.main.url(forResource: htmlFileName, withExtension: "html") else {
            return
        }
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }
}

struct ContentView: View {
    private let screens: [(title: String, file: String)] = [
        ("Classic", "Classic"),
        ("Modern", "Modern"),
        ("Playful", "Playful"),
        ("Play", "Play")
    ]

    @State private var selected = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("Screen", selection: $selected) {
                ForEach(screens.indices, id: \.self) { index in
                    Text(screens[index].title).tag(index)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            WebView(htmlFileName: screens[selected].file)
                .id(selected)
        }
    }
}

#Preview {
    ContentView()
}
