import SwiftUI
import UniformTypeIdentifiers

struct InstallROMSheet: View {
    @EnvironmentObject var romLibrary: ROMLibrary
    @EnvironmentObject var settings: SettingsStore
    @Environment(.dismiss) private var dismiss

    @State private var installMode: InstallMode = .file
    @State private var urlText = ""
    @State private var nameText = ""
    @State private var system = "NDS"
    @State private var isImporting = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedFileName: String?

    enum InstallMode: String, CaseIterable {
        case file = "File"
        case url = "URL"
    }

    let systems = ["NDS", "GBA", "GB", "GBC", "NES", "SNES", "N64", "PS1", "Genesis", "SMS", "PCE", "Other"]

    private var allowedTypes: [UTType] {
        // .data is intentionally broad so Files/iCloud exposes ROMs even when
        // the extension is unknown to the system. We validate/copy the file ourselves.
        [.data, .item, .content]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                settings.backgroundColor.ignoresSafeArea()

                Form {
                    Section {
                        Picker("Method", selection: $installMode) {
                            ForEach(InstallMode.allCases, id: .self) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }

                    if installMode == .file {
                        Section("ROM file") {
                            Button {
                                errorMessage = nil
                                isImporting = true
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: "folder.badge.plus")
                                        .font(.title2)
                                        .foregroundStyle(settings.accentColor)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(selectedFileName ?? "Choose any ROM file")
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text("Files • iCloud Drive • On My iPhone • any extension")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.tertiary)
                                }
                                .contentShape(Rectangle())
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                        } footer: {
                            Text("The picker accepts generic data so .nds, .gba, .n64, .nes, archives and future ROM formats are not hidden.")
                        }
                    } else {
                        Section("ROM URL") {
                            TextField("https://…/game.nds", text: $urlText)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.URL)
                                .autocorrectionDisabled()
                        }
                    }

                    Section("Details") {
                        TextField("Display name", text: $nameText)
                        Picker("System", selection: $system) {
                            ForEach(systems, id: \.self) { Text($0).tag($0) }
                        }
                    }

                    if let errorMessage {
                        Section("Error") {
                            Text(errorMessage).foregroundStyle(.red).font(.footnote)
                        }
                    }

                    Section {
                        Button {
                            Task { await install() }
                        } label: {
                            HStack {
                                Spacer()
                                if isLoading {
                                    ProgressView()
                                } else {
                                    Label("Add to Library", systemImage: "plus.circle.fill")
                                        .font(.headline)
                                }
                                Spacer()
                            }
                        }
                        .disabled(isLoading || !canInstall)
                        .tint(settings.accentColor)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add ROM")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: allowedTypes,
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
        }
        .presentationDetents([.medium, .large])
        .preferredColorScheme(.dark)
    }

    private var canInstall: Bool {
        if installMode == .url {
            return !urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return selectedFileName != nil
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                errorMessage = "No file was selected."
                return
            }

            let access = url.startAccessingSecurityScopedResource()
            defer {
                if access { url.stopAccessingSecurityScopedResource() }
            }

            let fileName = url.lastPathComponent
            let ext = url.pathExtension.lowercased()

            selectedFileName = fileName
            if nameText.isEmpty {
                nameText = url.deletingPathExtension().lastPathComponent
            }
            if let detected = detectSystem(ext: ext) {
                system = detected
            }

            let game = romLibrary.addGame(
                name: nameText.isEmpty ? url.deletingPathExtension().lastPathComponent : nameText,
                system: system,
                fileName: fileName,
                sourceURL: url
            )

            if game.fileURL == nil {
                errorMessage = "The file picker worked, but the ROM could not be copied into the app sandbox."
                selectedFileName = nil
            } else {
                dismiss()
            }

        case .failure(let error):
            errorMessage = "File picker failed: \(error.localizedDescription)"
        }
    }

    private func detectSystem(ext: String) -> String? {
        switch ext {
        case "nds", "dsi": return "NDS"
        case "gba": return "GBA"
        case "gb": return "GB"
        case "gbc": return "GBC"
        case "nes", "fds": return "NES"
        case "sfc", "smc": return "SNES"
        case "n64", "z64", "v64": return "N64"
        case "iso", "bin", "cue", "chd", "pbp": return "PS1"
        case "md", "gen", "smd": return "Genesis"
        case "sms", "gg": return "SMS"
        case "pce": return "PCE"
        default: return nil
        }
    }

    private func install() async {
        guard installMode == .url else {
            if selectedFileName == nil { isImporting = true }
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            _ = try await romLibrary.addFromURL(
                urlText.trimmingCharacters(in: .whitespacesAndNewlines),
                name: nameText.isEmpty ? nil : nameText,
                system: system
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
