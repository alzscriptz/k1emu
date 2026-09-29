import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var appState: AppState
    @StateObject private var coreLoader = CoreLoader.shared
    @State private var showResetAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground().ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        hero

                        settingsCard(title: "Appearance", icon: "paintpalette.fill") {
                            colorRow("Background", color: $settings.backgroundColor)
                            presetStrip(SettingsStore.backgroundPresets) { settings.backgroundColor = $0 }

                            colorRow("Accent", color: $settings.accentColor)
                            presetStrip(SettingsStore.accentPresets) { settings.accentColor = $0 }

                            Picker("Background", selection: $settings.backgroundEffect) {
                                ForEach(BackgroundEffect.allCases) { effect in
                                    Text(effect.rawValue).tag(effect)
                                }
                            }

                            Toggle("Liquid glass surfaces", isOn: $settings.useLiquidGlass)
                                .tint(settings.accentColor)
                        }

                        settingsCard(title: "Controller", icon: "gamecontroller.fill") {
                            colorRow("Base", color: $settings.joystickColor)
                            colorRow("Accent", color: $settings.joystickAccent)

                            Text("Controller presets")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(SettingsStore.joystickPresets, id: \.0) { name, base, accent in
                                        Button {
                                            settings.joystickColor = base
                                            settings.joystickAccent = accent
                                        } label: {
                                            HStack(spacing: 6) {
                                                Circle().fill(base).frame(width: 16, height: 16)
                                                Circle().fill(accent).frame(width: 16, height: 16)
                                                Text(name).font(.caption.weight(.semibold))
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 8)
                                            .background(.white.opacity(0.06), in: Capsule())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        settingsCard(title: "Performance", icon: "gauge.with.dots.needle.67percent") {
                            Toggle(isOn: $settings.showFPS) {
                                Label("Live FPS overlay", systemImage: "speedometer")
                            }
                            .tint(settings.accentColor)

                            Toggle(isOn: $settings.target4KWhenStable) {
                                Label("Prefer 4K external output", systemImage: "4k.tv")
                            }
                            .tint(settings.accentColor)

                            Text("FPS is measured from real display callbacks. It is never simulated. The external-display shell reports 4K only when the connected display actually exposes a 3840×2160-class mode.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        settingsCard(title: "TV & External Display", icon: "tv.fill") {
                            Toggle(isOn: $settings.tvModeEnabled) {
                                Label("External display mode", systemImage: "rectangle.inset.filled.and.person.filled")
                            }
                            .tint(settings.accentColor)

                            Toggle(isOn: $settings.autoEnterControllerOnExternalDisplay) {
                                Text("Automatically switch phone to controller")
                            }
                            .tint(settings.accentColor)
                            .disabled(!settings.tvModeEnabled)

                            if appState.isPlaying {
                                HStack {
                                    Circle()
                                        .fill(settings.tvModeEnabled ? .green : .orange)
                                        .frame(width: 8, height: 8)
                                    Text(appState.isTVModeActive ? "Controller mode active" : "Phone gameplay active")
                                        .font(.caption.weight(.semibold))
                                    Spacer()
                                }
                            }
                        }

                        settingsCard(title: "Emulator cores", icon: "cpu.fill") {
                            let cores = coreLoader.listAvailableCores()
                            if cores.isEmpty {
                                Label("No bundled dylibs detected", systemImage: "exclamationmark.triangle")
                                    .foregroundStyle(.orange)
                            } else {
                                ForEach(cores, id: \.self) { name in
                                    HStack {
                                        Image(systemName: "shippingbox.fill")
                                            .foregroundStyle(settings.accentColor)
                                        Text(name)
                                            .font(.caption.monospaced())
                                        Spacer()
                                    }
                                }
                            }

                            if let error = coreLoader.lastError {
                                Text(error)
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                        }

                        settingsCard(title: "About", icon: "info.circle.fill") {
                            LabeledContent("Version", value: "1.5.0")
                            LabeledContent("Build", value: "5")
                            Text("K1emu")
                                .font(.headline)
                            Text("A clean, user-owned library with real file import, persistent settings, tweak files, live display FPS and external-display support.")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Button(role: .destructive) {
                                showResetAlert = true
                            } label: {
                                Label("Reset appearance & display settings", systemImage: "arrow.counterclockwise")
                            }
                            .padding(.top, 4)
                        }

                        Spacer(minLength: 36)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .alert("Reset settings?", isPresented: $showResetAlert) {
                Button("Reset", role: .destructive) { settings.resetToDefaults() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your ROM library and tweak files will not be deleted.")
            }
        }
    }

    private var hero: some View {
        HStack(spacing: 14) {
            K1Logo(size: 58)
            VStack(alignment: .leading, spacing: 3) {
                Text("K1 Control Center")
                    .font(.title2.bold())
                Text("Everything persists between launches.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(18)
        .background(cardBackground)
    }

    private func settingsCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 13) {
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
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
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
                    Button { onSelect(color) } label: {
                        VStack(spacing: 4) {
                            Circle()
                                .fill(color)
                                .frame(width: 30, height: 30)
                                .overlay(Circle().stroke(.white.opacity(0.25), lineWidth: 1))
                            Text(name)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

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
                    colors: [settings.accentColor.opacity(0.18), .clear],
                    center: .topTrailing,
                    startRadius: 20,
                    endRadius: 420
                )
            case .aurora:
                LinearGradient(
                    colors: [settings.accentColor.opacity(0.25), .cyan.opacity(0.12), settings.backgroundColor],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .mesh:
                MeshStyleBackground(accent: settings.accentColor)
            case .particles:
                RadialGradient(
                    colors: [settings.accentColor.opacity(0.20), .clear],
                    center: .center,
                    startRadius: 10,
                    endRadius: 500
                )
            case .liquid:
                LinearGradient(
                    colors: [settings.accentColor.opacity(0.18), .blue.opacity(0.08), settings.backgroundColor],
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
            Circle().fill(accent.opacity(0.20)).frame(width: 280).blur(radius: 80).offset(x: -80, y: -120)
            Circle().fill(.cyan.opacity(0.12)).frame(width: 220).blur(radius: 70).offset(x: 100, y: 80)
            Circle().fill(.purple.opacity(0.15)).frame(width: 200).blur(radius: 60).offset(x: 40, y: 220)
        }
    }
}
