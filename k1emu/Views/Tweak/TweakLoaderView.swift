import SwiftUI

struct TweakLoaderView: View {
    @EnvironmentObject var tweakStore: TweakStore
    @EnvironmentObject var settings: SettingsStore
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            ZStack {
                settings.backgroundColor.ignoresSafeArea()

                List {
                    ForEach(tweakStore.tweaks) { tweak in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(tweak.name)
                                    .font(.headline)
                                Spacer()
                                Text(tweak.system)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(settings.accentColor.opacity(0.2), in: Capsule())
                            }
                            if !tweak.description.isEmpty {
                                Text(tweak.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(tweak.fileName)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { tweakStore.delete(tweakStore.tweaks[$0]) }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Tweak Loader")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(settings.accentColor)
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddTweakSheet()
            }
        }
    }
}

struct AddTweakSheet: View {
    @EnvironmentObject var tweakStore: TweakStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var system = "All"
    @State private var fileName = ""

    let systems = ["All", "NES", "SNES", "N64", "GB", "GBA", "PS1", "Other"]

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                TextField("Description", text: $description)
                Picker("System", selection: $system) {
                    ForEach(systems, id: \.self) { Text($0) }
                }
                TextField("File name (.cht / .zip)", text: $fileName)
            }
            .navigationTitle("New Tweak")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let t = TweakItem(name: name, description: description, system: system, fileName: fileName)
                        tweakStore.add(t)
                        dismiss()
                    }
                    .disabled(name.isEmpty || fileName.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
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
                Button("None (clear tweak)") {
                    var g = game
                    g.appliedTweakID = nil
                    romLibrary.update(g)
                    appState.loadedTweakName = nil
                    dismiss()
                }
                ForEach(tweakStore.tweaks.filter { $0.system == "All" || $0.system == game.system }) { tweak in
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
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
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
    }
}
