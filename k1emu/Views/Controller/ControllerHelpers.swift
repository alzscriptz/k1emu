import SwiftUI
import UIKit
import WebKit

// MARK: - Mode dots (cursor / chip8 / browser)

struct ModeDot: View {
    let active: Bool
    let color: Color
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(active ? color : Color.black.opacity(0.55))
                .frame(width: 11, height: 11)
                .overlay(
                    Circle()
                        .stroke(active ? color : Color.clear, lineWidth: 2)
                        .frame(width: 18, height: 18)
                )
                .shadow(color: active ? color.opacity(0.55) : .clear, radius: 7)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressPopStyle())
        .accessibilityLabel(label)
    }
}

// MARK: - CHIP-8 hex keypad

struct Chip8Keypad: View {
    private let rows: [[(String, Int)]] = [
        [("1", 1), ("2", 2), ("3", 3), ("C", 0xC)],
        [("4", 4), ("5", 5), ("6", 6), ("D", 0xD)],
        [("7", 7), ("8", 8), ("9", 9), ("E", 0xE)],
        [("A", 0xA), ("0", 0), ("B", 0xB), ("F", 0xF)],
    ]

    var body: some View {
        VStack(spacing: 3) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 3) {
                    ForEach(row, id: \.1) { label, key in
                        Chip8Key(label: label, key: key)
                    }
                }
            }
        }
        .padding(4)
    }
}

struct Chip8Key: View {
    let label: String
    let key: Int
    @State private var pressed = false

    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(pressed ? Color.orange.opacity(0.7) : Color.white.opacity(0.14))
            )
            .scaleEffect(pressed ? 0.92 : 1)
            .animation(.spring(response: 0.12, dampingFraction: 0.7), value: pressed)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !pressed {
                            pressed = true
                            Chip8Core.shared.setKey(key, pressed: true)
                        }
                    }
                    .onEnded { _ in
                        pressed = false
                        Chip8Core.shared.setKey(key, pressed: false)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
            )
    }
}

// MARK: - Shoulders

struct ShoulderCap: View {
    let label: String
    let color: Color
    @State private var pressed = false

    var body: some View {
        Text(label)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(Color(white: 0.35))
            .frame(width: max(44, CGFloat(label.count) * 14 + 16), height: 22)
            .background(Capsule().fill(color))
            .scaleEffect(pressed ? 0.92 : 1)
            .animation(.spring(response: 0.15, dampingFraction: 0.65), value: pressed)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !pressed {
                            pressed = true
                            if let id = InputBridge.shoulderId(label) {
                                InputBridge.shared.set(id, pressed: true)
                            }
                        }
                    }
                    .onEnded { _ in
                        pressed = false
                        if let id = InputBridge.shoulderId(label) {
                            InputBridge.shared.set(id, pressed: false)
                        }
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    }
            )
    }
}

// MARK: - Face button

struct FaceButton: View {
    let color: Color
    let label: String
    let radius: CGFloat
    @State private var pressed = false

    var body: some View {
        Text(label)
            .font(.system(size: radius * 0.72, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: radius * 2, height: radius * 2)
            .background(
                Circle()
                    .fill(color)
                    .shadow(color: color.opacity(pressed ? 0.55 : 0.22), radius: pressed ? 10 : 4, y: 2)
            )
            .scaleEffect(pressed ? 0.88 : 1)
            .animation(.spring(response: 0.13, dampingFraction: 0.6), value: pressed)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !pressed {
                            pressed = true
                            if let id = InputBridge.faceId(label) {
                                InputBridge.shared.set(id, pressed: true)
                            }
                        }
                    }
                    .onEnded { _ in
                        pressed = false
                        if let id = InputBridge.faceId(label) {
                            InputBridge.shared.set(id, pressed: false)
                        }
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
            )
    }
}

// MARK: - Stick (dark on white bg — matches reference)

struct RefStick: View {
    @Binding var offset: CGSize
    var size: CGFloat = 100
    private var maxTravel: CGFloat { size * 0.22 }
    private var knob: CGFloat { size * 0.58 }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(white: 0.72), lineWidth: size * 0.11)
                .background(Circle().fill(Color(white: 0.92)))
                .frame(width: size, height: size)
            Circle()
                .fill(Color.black)
                .frame(width: knob, height: knob)
                .offset(offset)
                .gesture(
                    DragGesture()
                        .onChanged { v in
                            offset = CGSize(
                                width: max(-maxTravel, min(maxTravel, v.translation.width)),
                                height: max(-maxTravel, min(maxTravel, v.translation.height))
                            )
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.22, dampingFraction: 0.7)) {
                                offset = .zero
                            }
                        }
                )
        }
    }
}

struct PressPopStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.15, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - In-panel browser (legacy small)

struct InPanelBrowser: View {
    @EnvironmentObject var appState: AppState
    @State private var url = URL(string: "https://search.brave.com")!

    var body: some View {
        ZStack(alignment: .topTrailing) {
            MiniWebView(url: $url)
            Button { appState.showBrowserInPanel = false } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(6)
            }
        }
    }
}

struct MiniWebView: UIViewRepresentable {
    @Binding var url: URL
    func makeUIView(context: Context) -> WKWebView {
        let w = WKWebView()
        w.isOpaque = false
        w.backgroundColor = .black
        w.scrollView.isScrollEnabled = true
        w.load(URLRequest(url: url))
        return w
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if uiView.url != url { uiView.load(URLRequest(url: url)) }
    }
}
