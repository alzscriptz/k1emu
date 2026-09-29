import SwiftUI

struct TweakLoaderView: View {
    @EnvironmentObject var tweakStore: TweakStore
    @EnvironmentObject var settings: SettingsStore
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground().ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Tweak Loader")
                                    .font(.title2.bold())
                                Text("Presets + your custom tweaks")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button { showAdd = true } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(settings.accentColor)
                            }
                        }
                        .padding(.horizontal, 16)

                        // Presets
                        sectionTitle("Presets", icon: "star.fill")
                        ForEach(tweakStore.presetTweaks) { tweak in
                            TweakRow(tweak: tweak, isPreset: true)
                                .padding(.horizontal, 16)
                        }

                        // Custom
                        if !tweakStore.customTweaks.isEmpty {
                            sectionTitle("Your Tweaks", icon: "slider.horizontal.3")
                            ForEach(tweakStore.customTweaks) { tweak in
                                TweakRow(tweak: tweak, isPreset: false)
                                    .padding(.horizontal, 16)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            tweakStore.delete(tweak)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }

                        // Add CTA
                        Button { showAdd = true } label: {
                            HStack {
                                Image(systemName: "plus")
                                Text("Add Custom Tweak")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(settings.accentColor.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                            )
                            .foregroundStyle(settings.accentColor)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAdd) {
                AddTweakSheet()
            }
        }
    }

    private func sectionTitle(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(settings.accentColor)
            .padding(.horizontal, 16)
            .padding(.top, 8)
    }
}

struct TweakRow: View {
    let tweak: TweakItem
    let isPreset: Bool
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(settings.accentColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: isPreset ? "star.fill" : "wrench.and.screwdriver")
                    .foregroundStyle(settings.accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(tweak.name)
                    .font(.subheadline.weight(.semibold))
                if !tweak.description.isEmpty {
                    Text(tweak.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(tweak.system)
                .font(.caption2.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(settings.accentColor.opacity(0.15), in: Capsule())
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

struct AddTweakSheet: View {
    @EnvironmentObject var tweakStore: TweakStore
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var system = "All"
    @State private var fileName = ""

    let systems = ["All", "NES", "SNES", "N64", "GB", "GBA", "PS1", "Other"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Tweak") {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description)
                    Picker("System", selection: $system) {
                        ForEach(systems, id: \.self) { Text($0) }
                    }
                    TextField("File name (.cht)", text: $fileName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle("New Tweak")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let t = TweakItem(
                            name: name,
                            description: description,
                            system: system,
                            fileName: fileName.isEmpty ? "\(name.lowercased().replacingOccurrences(of: " ", with: "_")).cht" : fileName
                        )
                        tweakStore.add(t)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
        .preferredColorScheme(.dark)
    }
}

struct TweakPickerSheet: View {
    let game: GameItem
    @EnvironmentObject var romLibrary: ROMLibrary
    @EnvironmentObject var tweakStore: TweakStore
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Button {
                    var g = game
                    g.appliedTweakID = nil
                    romLibrary.update(g)
                    appState.loadedTweakName = nil
                    dismiss()
                } label: {
                    Label("None (clear)", systemImage: "xmark.circle")
                }

                Section("Presets") {
                    ForEach(tweakStore.presetTweaks.filter { $0.system == "All" || $0.system == game.system }) { tweak in
                        tweakButton(tweak)
                    }
                }

                if !tweakStore.customTweaks.isEmpty {
                    Section("Custom") {
                        ForEach(tweakStore.customTweaks.filter { $0.system == "All" || $0.system == game.system }) { tweak in
                            tweakButton(tweak)
                        }
                    }
                }
            }
            .navigationTitle("Load Tweak")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .preferredColorScheme(.dark)
    }

    private func tweakButton(_ tweak: TweakItem) -> some View {
        Button {
            var g = game
            g.appliedTweakID = tweak.id
            romLibrary.update(g)
            appState.loadedTweakName = tweak.name
            dismiss()
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(tweak.name)
                    Text(tweak.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if game.appliedTweakID == tweak.id {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                }
            }
        }
    }
}
