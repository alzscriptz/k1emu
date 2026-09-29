import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground()
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header card
                        headerCard

                        // Colors
                        settingsCard(title: "Colors", icon: "paintpalette.fill") {
                            colorRow("Background", color: $settings.backgroundColor)
                            presetStrip(SettingsStore.backgroundPresets.map { ($0.0, $0.1) }) { settings.backgroundColor = $0 }

                            colorRow("Accent", color: $settings.accentColor)
                            presetStrip(SettingsStore.accentPresets) { settings.accentColor = $0 }

                            colorRow("Joystick Base", color: $settings.joystickColor)
                            colorRow("Joystick Accent", color: $settings.joystickAccent)

                            Text("Joystick Presets")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            ForEach(SettingsStore.joystickPresets, id: \.0) { name, base, accent in
                                Button {
                                    settings.joystickColor = base
                                    settings.joystickAccent = accent
                                } label: {
                                    HStack(spacing: 10) {
                                        Circle().fill(base).frame(width: 22, height: 22)
                                            .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
                                        Circle().fill(accent).frame(width: 22, height: 22)
                                        Text(name).foregroundStyle(.primary)
                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // Background effect
                        settingsCard(title: "Background Effect", icon: "sparkles") {
                            ForEach(BackgroundEffect.allCases) { effect in
                                Button {
                                    settings.backgroundEffect = effect
                                    if effect == .liquid { settings.useLiquidGlass = true }
                                } label: {
                                    HStack {
                                        Text(effect.rawValue)
                                        Spacer()
                                        if settings.backgroundEffect == effect {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(settings.accentColor)
                                        }
                                    }
                                    .padding(.vertical, 6)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // Display / Performance
                        settingsCard(title: "Display & Performance", icon: "gauge.with.dots.needle.67percent") {
                            Toggle(isOn: $settings.showFPS) {
                                Label("Show FPS (top-right)", systemImage: "speedometer")
                            }
                            .tint(settings.accentColor)

                            Toggle(isOn: $settings.target4KWhenStable) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Label("4K when FPS stable", systemImage: "4k.tv")
                                    Text("Renders at full quality when frame time is steady")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .tint(settings.accentColor)

                            Toggle(isOn: $settings.useLiquidGlass) {
                                Label("Liquid Glass (iOS 18+/26+)", systemImage: "drop.fill")
                            }
                            .tint(settings.accentColor)
                        }

                        // TV mode
                        settingsCard(title: "TV / External Display", icon: "tv") {
                            Toggle(isOn: $settings.tvModeEnabled) {
                                Label("Enable TV Mode", systemImage: "tv.fill")
                            }
                            .tint(settings.accentColor)

                            Toggle(isOn: $settings.autoEnterControllerOnExternalDisplay) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Auto controller on connect")
                                    Text("Phone becomes Xbox-style pad; game goes to TV")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .tint(settings.accentColor)
                            .disabled(!settings.tvModeEnabled)
                        }

                        // About
                        settingsCard(title: "About", icon: "info.circle") {
                            LabeledContent("Version", value: "1.1.0")
                            LabeledContent("Build", value: "2")
                            Text("k1emu — all-systems ROM emulator")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    private var headerCard: some View {
        HStack(spacing: 14) {
            K1Logo(size: 52)
            VStack(alignment: .leading, spacing: 2) {
                Text("k1emu")
                    .font(.title2.bold())
                Text("Customize everything")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(cardBackground)
    }

    private func settingsCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(settings.accentColor)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.18), .white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }

    private func colorRow(_ title: String, color: Binding<Color>) -> some View {
        HStack {
            Text(title)
            Spacer()
            ColorPicker("", selection: color, supportsOpacity: false)
                .labelsHidden()
        }
    }

    private func presetStrip(_ items: [(String, Color)], onSelect: @escaping (Color) -> Void) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(items, id: \.0) { name, color in
                    Button {
                        onSelect(color)
                    } label: {
                        VStack(spacing: 4) {
                            Circle()
                                .fill(color)
                                .frame(width: 32, height: 32)
                                .overlay(Circle().stroke(.white.opacity(0.25), lineWidth: 1))
                            Text(name)
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// Shared animated background used across app
struct AnimatedBackground: View {
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        ZStack {
            settings.backgroundColor

            switch settings.backgroundEffect {
            case .none:
                EmptyView()
            case .subtle:
                RadialGradient(
                    colors: [settings.accentColor.opacity(0.15), .clear],
                    center: .topTrailing,
                    startRadius: 20,
                    endRadius: 420
                )
            case .aurora:
                LinearGradient(
                    colors: [
                        settings.accentColor.opacity(0.25),
                        Color.cyan.opacity(0.12),
                        settings.backgroundColor
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .mesh:
                MeshStyleBackground(accent: settings.accentColor)
            case .particles:
                RadialGradient(
                    colors: [settings.accentColor.opacity(0.2), .clear],
                    center: .center,
                    startRadius: 10,
                    endRadius: 500
                )
            case .liquid:
                LinearGradient(
                    colors: [
                        settings.accentColor.opacity(0.18),
                        Color.blue.opacity(0.08),
                        settings.backgroundColor
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
}

struct MeshStyleBackground: View {
    let accent: Color
    var body: some View {
        ZStack {
            Circle().fill(accent.opacity(0.2)).frame(width: 280).blur(radius: 80).offset(x: -80, y: -120)
            Circle().fill(Color.cyan.opacity(0.12)).frame(width: 220).blur(radius: 70).offset(x: 100, y: 80)
            Circle().fill(Color.purple.opacity(0.15)).frame(width: 200).blur(radius: 60).offset(x: 40, y: 220)
        }
    }
}
