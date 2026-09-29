import SwiftUI
import UniformTypeIdentifiers

struct TweakLoaderView: View {
    @EnvironmentObject var tweakStore: TweakStore
    @EnvironmentObject var settings: SettingsStore
    @State private var showAdd = false
    @State private var editingTweak: TweakItem?

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground().ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(spacing: 14) {
                            K1Logo(size: 46)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Tweak Lab").font(.title2.bold())
                                Text("Real files • presets • imports").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                editingTweak = nil
                                showAdd = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(settings.accentColor)
                            }
                        }
                        .padding(.horizontal, 16)

                        sectionTitle("Preset library", icon: "sparkles")
                        ForEach(tweakStore.presetTweaks) { tweak in
                            TweakRow(tweak: tweak, isPreset: true)
                                .padding(.horizontal, 16)
                        }

                        if !tweakStore.customTweaks.isEmpty {
                            sectionTitle("Your tweaks", icon: "wrench.and.screwdriver.fill")
                            ForEach(tweakStore.customTweaks) { tweak in
                                TweakRow(tweak: tweak, isPreset: false)
                                    .padding(.horizontal, 16)
                                    .contextMenu {
                                        Button {
                                            editingTweak = tweak
                                            showAdd = true
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        Button(role: .destructive) {
                                            tweakStore.delete(tweak)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }

                        Button {
                            editingTweak = nil
                            showAdd = true
                        } label: {
                            Label("Import / Create Tweak", systemImage: "plus")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(settings.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(settings.accentColor.opacity(0.45), lineWidth: 1)
                                )
                                .foregroundStyle(settings.accentColor)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100)
                    }
                    .padding(.top, 10)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showAdd, onDismiss: { editingTweak = nil }) {
                AddTweakSheet(tweak: editingTweak)
            }
        }
    }

    private func sectionTitle(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(settings.accentColor)
            .padding(.horizontal, 16)
            .padding(.top, 6)
    }
}

struct TweakRow: View {
    let tweak: TweakItem
    let isPreset: Bool
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(settings.accentColor.opacity(0.18))
                    .frame(width: 46, height: 46)
                Image(systemName: isPreset ? "sparkles" : "wrench.and.screwdriver")
                    .foregroundStyle(settings.accentColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(tweak.name).font(.subheadline.weight(.semibold))
                Text(tweak.description.isEmpty ? tweak.fileName : tweak.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Text(tweak.system)
                .font(.caption2.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(settings.accentColor.opacity(0.13), in: Capsule())
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }
}

struct AddTweakSheet: View {
    let tweak: TweakItem?
    @EnvironmentObject var tweakStore: TweakStore
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var description: String
    @State private var system: String
    @State private var fileName: String
    @State private var content: String
    @State private var importing = false
    @State private var error: String?

    let systems = ["All", "NDS", "NES", "SNES", "N64", "GB", "GBC", "GBA", "PS1", "Genesis", "SMS", "PCE", "Other"]

    init(tweak: TweakItem? = nil) {
        self.tweak = tweak
        _name = State(initialValue: tweak?.name ?? "")
        _description = State(initialValue: tweak?.description ?? "")
        _system = State(initialValue: tweak?.system ?? "All")
        _fileName = State(initialValue: tweak?.fileName ?? "")
        _content = State(initialValue: tweak?.content ?? "")
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Identity") {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description)
                    Picker("System", selection: $system) {
                        ForEach(systems, id: \.self) { item in Text(item) }
                    }
                    TextField("File name", text: $fileName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section {
                    Button {
                        error = nil
                        importing = true
                    } label: {
                        Label("Choose tweak file", systemImage: "doc.badge.plus")
                    }
                    .tint(settings.accentColor)

                    TextEditor(text: $content)
                        .font(.system(.footnote, design: .monospaced))
                        .frame(minHeight: 180)
                        .scrollContentBackground(.hidden)
                } header: {
                    Text("Tweak payload")
                } footer: {
                    Text("Choose a text cheat/tweak file, or paste its payload below.")
                }

                if let error {
                    Section {
                        Text(error).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(tweak == nil ? "Tweak Builder" : "Edit Tweak")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
            .fileImporter(
                isPresented: $importing,
                allowedContentTypes: [.data, .plainText, .item],
                allowsMultipleSelection: false
            ) { result in
                importFile(result)
            }
        }
        .presentationDetents([.large])
        .preferredColorScheme(.dark)
    }

    private func save() {
        let safeName = fileName.isEmpty
            ? name.lowercased().replacingOccurrences(of: " ", with: "_")
            : fileName
        let finalName = safeName.contains(".") ? safeName : safeName + ".cht"

        let value = TweakItem(
            id: tweak?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description,
            system: system,
            fileName: finalName,
            content: content,
            dateAdded: tweak?.dateAdded ?? Date(),
            isEnabled: tweak?.isEnabled ?? true
        )

        if tweak == nil {
            tweakStore.add(value)
        } else {
            tweakStore.update(value)
        }
        dismiss()
    }

    private func importFile(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                error = "No tweak file was selected."
                return
            }

            let access = url.startAccessingSecurityScopedResource()
            defer {
                if access {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            do {
                content = try String(contentsOf: url, encoding: .utf8)
                if fileName.isEmpty {
                    fileName = url.lastPathComponent
                }
                if name.isEmpty {
                    name = url.deletingPathExtension().lastPathComponent
                }
                error = nil
            } catch {
                self.error = "Could not read this tweak as UTF-8 text. Try a text-based .cht/.txt/.ini file."
            }

        case .failure(let error):
            self.error = "Import failed: \(error.localizedDescription)"
        }
    }
}

struct TweakPickerSheet: View {
    let game: GameItem
    @EnvironmentObject var romLibrary: ROMLibrary
    @EnvironmentObject var tweakStore: TweakStore
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var compatibleTweaks: [TweakItem] {
        tweakStore.tweaks.filter {
            $0.isEnabled && ($0.system == "All" || $0.system.caseInsensitiveCompare(game.system) == .orderedSame)
        }
    }

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

                Section("Compatible tweaks") {
                    if compatibleTweaks.isEmpty {
                        Text("No compatible tweaks yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(compatibleTweaks) { item in
                            Button {
                                var g = game
                                g.appliedTweakID = item.id
                                romLibrary.update(g)
                                appState.loadedTweakName = item.name
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(item.name)
                                        Text(item.fileName)
                                            .font(.caption2.monospaced())
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if game.appliedTweakID == item.id {
                                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                    }
                                }
                            }
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
}
