import OSLog
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
            Log.app.error("Missing bundled screen \(htmlFileName).html")
            return
        }
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }
}

/// A bundled HTML screen and the title shown for it in the screen picker.
struct Screen: Identifiable {
    let title: LocalizedStringResource
    let file: String

    var id: String { file }

    static let all = [
        Screen(title: "Classic", file: "Classic"),
        Screen(title: "Modern", file: "Modern"),
        Screen(title: "Playful", file: "Playful"),
        Screen(title: "Play", file: "Play"),
    ]
}

struct ContentView: View {
    @State private var selected = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("Screen", selection: $selected) {
                ForEach(Screen.all.indices, id: \.self) { index in
                    Text(Screen.all[index].title).tag(index)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            WebView(htmlFileName: Screen.all[selected].file)
                .id(selected)
        }
    }
}

#Preview {
    ContentView()
}
