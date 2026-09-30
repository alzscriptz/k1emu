import SwiftUI
import UniformTypeIdentifiers

struct TweakLoaderView: View {
    @EnvironmentObject var tweakStore: TweakStore
    @EnvironmentObject var settings: SettingsStore
    @State private var showAdd = false
    @State private var showPresets = false
    @State private var showMine = false
    @State private var editingTweak: TweakItem?

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground().ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Tweak Lab")
                                    .font(.system(size: 30, weight: .black, design: .rounded))
                                Text("Tune your games")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                editingTweak = nil
                                showAdd = true
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 42, height: 42)
                                    .background(settings.accentColor, in: Circle())
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.bottom, 4)

                        Button { showPresets = true } label: {
                            labRow(icon: "star.fill", title: "Preset Tweaks", subtitle: "Built-in presets")
                        }
                        .buttonStyle(.plain)

                        Button { showMine = true } label: {
                            labRow(icon: "doc.text.fill", title: "My Tweaks", subtitle: "Manage your tweaks")
                        }
                        .buttonStyle(.plain)

                        Button {
                            editingTweak = nil
                            showAdd = true
                        } label: {
                            labRow(icon: "plus.circle.fill", title: "Add Tweak", subtitle: "Import or create")
                        }
                        .buttonStyle(.plain)

                        if !tweakStore.customTweaks.isEmpty {
                            Text("Recently added")
                                .font(.headline)
                                .padding(.top, 8)
                            ForEach(tweakStore.customTweaks.prefix(3)) { tweak in
                                TweakRow(tweak: tweak, isPreset: false)
                            }
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(16)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showAdd, onDismiss: { editingTweak = nil }) {
                AddTweakSheet(tweak: editingTweak)
            }
            .sheet(isPresented: $showPresets) {
                TweakListSheet(title: "Preset Tweaks", tweaks: tweakStore.presetTweaks, canEdit: false)
            }
            .sheet(isPresented: $showMine) {
                TweakListSheet(title: "My Tweaks", tweaks: tweakStore.customTweaks, canEdit: true)
            }
        }
    }

    private func labRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(settings.accentColor)
                .frame(width: 34)

            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .frame(height: 76)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.12), lineWidth: 1))
    }
}

struct TweakListSheet: View {
    let title: String
    let tweaks: [TweakItem]
    let canEdit: Bool
    @EnvironmentObject var tweakStore: TweakStore
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
    @State private var editing: TweakItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    if tweaks.isEmpty {
                        ContentUnavailableView("No tweaks yet", systemImage: "slider.horizontal.3")
                    } else {
                        ForEach(tweaks) { tweak in
                            TweakRow(tweak: tweak, isPreset: !canEdit)
                                .contextMenu {
                                    if canEdit {
                                        Button {
                                            editing = tweak
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
                    }
                }
                .padding(16)
            }
            .background(AnimatedBackground().ignoresSafeArea())
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $editing) { AddTweakSheet(tweak: $0) }
        }
        .preferredColorScheme(.dark)
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
        .overlay(RoundedRectangle(cornerRadius: 17).stroke(.white.opacity(0.08), lineWidth: 1))
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
                        ForEach(systems, id: \.self) { Text($0) }
                    }
                    TextField("File name", text: $fileName)
                }

                Section("Tweak payload") {
                    Button {
                        error = nil
                        importing = true
                    } label: {
                        Label("Choose tweak file", systemImage: "doc.badge.plus")
                    }
                    .tint(settings.accentColor)

                    TextEditor(text: $content)
                        .font(.system(.footnote, design: .monospaced))
                        .frame(minHeight: 190)
                }

                if let error {
                    Text(error).foregroundStyle(.red)
                }
            }
            .navigationTitle(tweak == nil ? "Add Tweak" : "Edit Tweak")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!canSave)
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
        let safeName = fileName.isEmpty ? name.lowercased().replacingOccurrences(of: " ", with: "_") : fileName
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
        tweak == nil ? tweakStore.add(value) : tweakStore.update(value)
        dismiss()
    }

    private func importFile(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { error = "No tweak file was selected."; return }
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            do {
                let data = try Data(contentsOf: url, options: [.mappedIfSafe])
                content = String(decoding: data, as: UTF8.self)
                if fileName.isEmpty { fileName = url.lastPathComponent }
                if name.isEmpty { name = url.deletingPathExtension().lastPathComponent }
                error = nil
            } catch {
                self.error = "Could not import this tweak file."
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
        tweakStore.tweaks.filter { $0.isEnabled && ($0.system == "All" || $0.system.caseInsensitiveCompare(game.system) == .orderedSame) }
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
                } label: { Label("None (clear)", systemImage: "xmark.circle") }

                Section("Compatible tweaks") {
                    if compatibleTweaks.isEmpty {
                        Text("No compatible tweaks yet.").foregroundStyle(.secondary)
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
                                    VStack(alignment: .leading) {
                                        Text(item.name)
                                        Text(item.fileName).font(.caption2.monospaced()).foregroundStyle(.secondary)
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
        }
        .presentationDetents([.medium, .large])
    }
}
