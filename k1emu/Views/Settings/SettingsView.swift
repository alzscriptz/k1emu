import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            ZStack {
                settings.backgroundColor.ignoresSafeArea()

                Form {
                    Section("Appearance") {
                        Toggle("Liquid Glass (iOS 18+/26+)", isOn: $settings.useLiquidGlass)

                        ColorPicker("Background", selection: $settings.backgroundColor, supportsOpacity: false)
                        ColorPicker("Accent", selection: $settings.accentColor, supportsOpacity: false)
                        ColorPicker("Joystick Base", selection: $settings.joystickColor, supportsOpacity: false)
                        ColorPicker("Joystick Accent", selection: $settings.joystickAccent, supportsOpacity: false)
                    }

                    Section("Background Presets") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(SettingsStore.backgroundPresets, id: \.0) { name, color in
                                    Button {
                                        settings.backgroundColor = color
                                    } label: {
                                        VStack {
                                            Circle()
                                                .fill(color)
                                                .frame(width: 36, height: 36)
                                                .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 1))
                                            Text(name)
                                                .font(.caption2)
                                                .lineLimit(1)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    Section("Joystick Presets") {
                        ForEach(SettingsStore.joystickPresets, id: \.0) { name, base, accent in
                            Button {
                                settings.joystickColor = base
                                settings.joystickAccent = accent
                            } label: {
                                HStack {
                                    Circle().fill(base).frame(width: 24, height: 24)
                                    Circle().fill(accent).frame(width: 24, height: 24)
                                    Text(name)
                                    Spacer()
                                }
                            }
                        }
                    }

                    Section("tvOS / External Display") {
                        Toggle("Enable TV Mode Support", isOn: $settings.tvModeEnabled)
                        Toggle("Auto enter controller when external display connected", isOn: $settings.autoEnterControllerOnExternalDisplay)
                            .disabled(!settings.tvModeEnabled)

                        Text("When your iPhone is connected to a TV, monitor or AirPlay, the game picture is shown only on the big screen and the phone becomes a full Xbox-style controller.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Section("About") {
                        LabeledContent("Version", value: "1.0.0")
                        LabeledContent("Build", value: "1")
                        Text("k1emu – all-types ROM emulator")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
        }
    }
}
