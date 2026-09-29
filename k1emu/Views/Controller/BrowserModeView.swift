import SwiftUI
import WebKit

struct BrowserModeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsStore
    @State private var urlString = "https://www.google.com"
    @State private var currentURL: URL = URL(string: "https://www.google.com")!
    @State private var showKeyboard = false
    @State private var addressText = "https://www.google.com"

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack(spacing: 10) {
                Button {
                    appState.isBrowserMode = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }

                TextField("URL", text: $addressText)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onSubmit { loadURL() }

                Button("Go") { loadURL() }
                    .buttonStyle(.borderedProminent)
                    .tint(settings.joystickAccent)
            }
            .padding(10)
            .background(.ultraThinMaterial)

            // Web view
            WebView(url: $currentURL)
                .ignoresSafeArea(edges: .bottom)

            // Mini keyboard toggle
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
                    Label(showKeyboard ? "Hide Keyboard" : "Show Keyboard", systemImage: "keyboard")
                        .font(.caption)
                }
                Spacer()
                if appState.isMouseMode {
                    Text("MOUSE ON")
                        .font(.caption2.bold())
                        .foregroundStyle(.blue)
                }
            }
            .padding(8)
            .background(.ultraThinMaterial)
        }
    }

    private func loadURL() {
        var s = addressText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !s.hasPrefix("http") { s = "https://" + s }
        if let url = URL(string: s) {
            currentURL = url
            addressText = s
        }
    }
}

struct WebView: UIViewRepresentable {
    @Binding var url: URL

    func makeUIView(context: Context) -> WKWebView {
        let web = WKWebView()
        web.load(URLRequest(url: url))
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if uiView.url != url {
            uiView.load(URLRequest(url: url))
        }
    }
}

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
