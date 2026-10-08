import SwiftUI
import WebKit

struct BrowserModeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsStore

    // Brave Search as default (privacy-first)
    @State private var addressText = "https://search.brave.com"
    @State private var currentURL: URL = URL(string: "https://search.brave.com")!
    @State private var showKeyboard = false
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var isLoading = false
    @State private var pageTitle = "Brave Search"

    var body: some View {
        VStack(spacing: 0) {
            // Clean Brave-style top bar
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    Button {
                        appState.isBrowserMode = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.9))
                    }

                    // Address bar
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.green.opacity(0.85))

                        TextField("Search or enter URL", text: $addressText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 15))
                            .foregroundStyle(.primary)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .onSubmit { loadURL() }

                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )

                    Button("Go") { loadURL() }
                        .font(.subheadline.weight(.semibold))
                        .buttonStyle(.borderedProminent)
                        .tint(settings.joystickAccent)
                }

                // Navigation + privacy row
                HStack(spacing: 18) {
                    Button { /* goBack via coordinator later */ } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(canGoBack ? .primary : .secondary.opacity(0.4))
                    }
                    .disabled(!canGoBack)

                    Button { /* goForward */ } label: {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(canGoForward ? .primary : .secondary.opacity(0.4))
                    }
                    .disabled(!canGoForward)

                    Button { loadURL() } label: {
                        Image(systemName: "arrow.clockwise")
                    }

                    Spacer()

                    // Privacy badge
                    HStack(spacing: 4) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.caption)
                        Text("Shields")
                            .font(.caption2.weight(.medium))
                    }
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.orange.opacity(0.15)))

                    if appState.isMouseMode {
                        Text("CURSOR")
                            .font(.caption2.bold())
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.blue.opacity(0.15)))
                    }
                }
                .font(.body)
                .foregroundStyle(.primary)
            }
            .padding(10)
            .background(.ultraThinMaterial)

            // Web content
            WebView(
                url: $currentURL,
                isLoading: $isLoading,
                canGoBack: $canGoBack,
                canGoForward: $canGoForward,
                pageTitle: $pageTitle
            )
            .ignoresSafeArea(edges: .bottom)

            // Optional mini keyboard for controller use
            if showKeyboard {
                MiniKeyboardView(text: $addressText) {
                    loadURL()
                }
                .transition(.move(edge: .bottom))
            }

            HStack {
                Button {
                    withAnimation { showKeyboard.toggle() }
                } label: {
                    Label(showKeyboard ? "Hide Keyboard" : "Keyboard", systemImage: "keyboard")
                        .font(.caption)
                }
                Spacer()
                Text(pageTitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(8)
            .background(.ultraThinMaterial)
        }
    }

    private func loadURL() {
        var s = addressText.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.isEmpty { return }

        // If it looks like a search query, route to Brave Search
        if !s.contains(".") && !s.hasPrefix("http") {
            s = "https://search.brave.com/search?q=" + s.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        } else if !s.hasPrefix("http") {
            s = "https://" + s
        }

        if let url = URL(string: s) {
            currentURL = url
            addressText = s
        }
    }
}

// MARK: - WebView with basic state

struct WebView: UIViewRepresentable {
    @Binding var url: URL
    @Binding var isLoading: Bool
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var pageTitle: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        // Basic privacy-oriented config
        config.preferences.javaScriptCanOpenWindowsAutomatically = false

        let web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = context.coordinator
        web.allowsBackForwardNavigationGestures = true
        web.load(URLRequest(url: url))
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if uiView.url != url {
            uiView.load(URLRequest(url: url))
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            parent.canGoBack = webView.canGoBack
            parent.canGoForward = webView.canGoForward
            parent.pageTitle = webView.title ?? ""
            if let current = webView.url {
                parent.url = current
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
    }
}

// MARK: - Mini keyboard for controller

struct MiniKeyboardView: View {
    @Binding var text: String
    var onSubmit: () -> Void

    private let rows = [
        ["1","2","3","4","5","6","7","8","9","0"],
        ["q","w","e","r","t","y","u","i","o","p"],
        ["a","s","d","f","g","h","j","k","l"],
        ["z","x","c","v","b","n","m",".","/"]
    ]

    var body: some View {
        VStack(spacing: 6) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(row, id: \.self) { key in
                        Button {
                            text += key
                        } label: {
                            Text(key)
                                .font(.system(size: 16, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            HStack {
                Button("space") { text += " " }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                Button("⌫") {
                    if !text.isEmpty { text.removeLast() }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                Button("Go") { onSubmit() }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue.opacity(0.7), in: RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(.ultraThinMaterial)
    }
}
