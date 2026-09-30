import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var appState: AppState
    @StateObject private var coreLoader = CoreLoader.shared
    @State private var showResetAlert = false
    @State private var selected: SettingsSection?

    enum SettingsSection: String, Identifiable, CaseIterable {
        case appearance = "Appearance"
        case controller = "Controller"
        case performance = "Performance"
        case display = "TV & Display"
        case core = "Core"
        case advanced = "Advanced"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground().ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        header

                        ForEach(SettingsSection.allCases) { section in
                            Button {
                                selected = section
                            } label: {
                                settingsRow(section)
                            }
                            .buttonStyle(.plain)
                        }

                        Button(role: .destructive) {
                            showResetAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Reset to Default")
                                Spacer()
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 18)
                            .frame(height: 58)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                        .padding(.bottom, 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $selected) { section in
                SettingsDetailView(section: section)
            }
            .alert("Reset settings?", isPresented: $showResetAlert) {
                Button("Reset", role: .destructive) { settings.resetToDefaults() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your ROM library and tweak files will not be deleted.")
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Settings")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                Text("Customize k1emu")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "gearshape.fill")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(settings.accentColor)
        }
        .padding(.horizontal, 6)
        .padding(.bottom, 8)
    }

    private func settingsRow(_ section: SettingsSection) -> some View {
        let icon: String
        let subtitle: String
        switch section {
        case .appearance: icon = "paintpalette.fill"; subtitle = "Theme • Icon • Effects"
        case .controller: icon = "gamecontroller.fill"; subtitle = "Layout • Haptics • Vibration"
        case .performance: icon = "gauge.with.dots.needle.67percent"; subtitle = "FPS • Resolution • 4K"
        case .display: icon = "tv.fill"; subtitle = "External Display • FPS"
        case .core: icon = "cpu.fill"; subtitle = "Emulation • BIOS • Region"
        case .advanced: icon = "slider.horizontal.3"; subtitle = "Tweaks • Debug • Logs"
        }

        return HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(settings.accentColor)
                .frame(width: 34)

            VStack(alignment: .leading, spacing: 3) {
                Text(section.rawValue)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .frame(height: 70)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 19).stroke(.white.opacity(0.12), lineWidth: 1))
    }
}

struct SettingsDetailView: View {
    let section: SettingsView.SettingsSection
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var appState: AppState
    @StateObject private var coreLoader = CoreLoader.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    switch section {
                    case .appearance: appearance
                    case .controller: controller
                    case .performance: performance
                    case .display: display
                    case .core: core
                    case .advanced: advanced
                    }
                }
                .padding(16)
            }
            .background(AnimatedBackground().ignoresSafeArea())
            .navigationTitle(section.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var appearance: some View {
        VStack(alignment: .leading, spacing: 16) {
            settingColor("Background", $settings.backgroundColor)
            settingColor("Accent", $settings.accentColor)
            Picker("Background Effect", selection: $settings.backgroundEffect) {
                ForEach(BackgroundEffect.allCases) { Text($0.rawValue).tag($0) }
            }
            Toggle("Liquid glass surfaces", isOn: $settings.useLiquidGlass).tint(settings.accentColor)
        }
        .cardStyle()
    }

    private var controller: some View {
        VStack(alignment: .leading, spacing: 16) {
            settingColor("Base", $settings.joystickColor)
            settingColor("Accent", $settings.joystickAccent)
            Text("Controller presets").font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
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
                            .padding(10)
                            .background(.white.opacity(0.07), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .cardStyle()
    }

    private var performance: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Live FPS overlay", isOn: $settings.showFPS).tint(settings.accentColor)
            Toggle("Prefer 4K external output", isOn: $settings.target4KWhenStable).tint(settings.accentColor)
            Text("FPS is measured from real display callbacks. The TV shell keeps a true 16:9 presentation.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .cardStyle()
    }

    private var display: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("External display mode", isOn: $settings.tvModeEnabled).tint(settings.accentColor)
            Toggle("Automatically switch phone to controller", isOn: $settings.autoEnterControllerOnExternalDisplay)
                .tint(settings.accentColor)
                .disabled(!settings.tvModeEnabled)
            HStack {
                Circle().fill(settings.tvModeEnabled ? .green : .orange).frame(width: 8, height: 8)
                Text(appState.isTVModeActive ? "Controller mode active" : "Phone gameplay active")
                    .font(.caption.weight(.semibold))
            }
        }
        .cardStyle()
    }

    private var core: some View {
        VStack(alignment: .leading, spacing: 12) {
            let cores = coreLoader.listAvailableCores()
            if cores.isEmpty {
                Label("No bundled dylibs detected", systemImage: "exclamationmark.triangle").foregroundStyle(.orange)
            } else {
                ForEach(cores, id: \.self) { name in
                    Label(name, systemImage: "shippingbox.fill")
                        .font(.caption.monospaced())
                        .foregroundStyle(settings.accentColor)
                }
            }
            if let error = coreLoader.lastError {
                Text(error).font(.caption2).foregroundStyle(.orange)
            }
        }
        .cardStyle()
    }

    private var advanced: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Tweak engine", systemImage: "slider.horizontal.3")
            Label("Debug logs", systemImage: "ladybug.fill")
            Label("Diagnostics", systemImage: "waveform.path.ecg")
            Text("Advanced tools stay out of the way until you need them.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .cardStyle()
    }

    private func settingColor(_ title: String, _ binding: Binding<Color>) -> some View {
        HStack {
            Text(title)
            Spacer()
            ColorPicker("", selection: binding, supportsOpacity: false).labelsHidden()
        }
    }
}

private extension View {
    func cardStyle() -> some View {
        self
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.12), lineWidth: 1))
    }
}
