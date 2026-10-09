import SwiftUI
import WebKit

// MARK: - Full-screen browser with address bar + keyboard

struct FullBrowserSheet: View {
    @EnvironmentObject var appState: AppState
    @State private var urlString = "https://search.brave.com"
    @State private var currentURL = URL(string: "https://search.brave.com")!
    @FocusState private var urlFocused: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
                .onTapGesture { appState.showBrowserInPanel = false }

            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Button {
                        appState.showBrowserInPanel = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    HStack {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                        TextField("Search or URL", text: $urlString)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .focused($urlFocused)
                            .foregroundStyle(.white)
                            .onSubmit { go() }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.12)))

                    Button("Go") { go() }
                        .font(.subheadline.bold())
                        .foregroundStyle(.cyan)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(white: 0.12))

                BrowserWebView(url: $currentURL)
                    .background(Color.black)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 8)
            .padding(.vertical, 40)
        }
    }

    private func go() {
        var s = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if !s.contains(".") && !s.hasPrefix("http") {
            s = "https://search.brave.com/search?q=" + (s.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? s)
        } else if !s.hasPrefix("http") {
            s = "https://" + s
        }
        if let u = URL(string: s) {
            currentURL = u
            urlString = s
        }
        urlFocused = false
    }
}

struct BrowserWebView: UIViewRepresentable {
    @Binding var url: URL
    func makeUIView(context: Context) -> WKWebView {
        let w = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        w.allowsBackForwardNavigationGestures = true
        w.load(URLRequest(url: url))
        return w
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if uiView.url?.absoluteString != url.absoluteString {
            uiView.load(URLRequest(url: url))
        }
    }
}
