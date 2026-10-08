import SwiftUI
import UniformTypeIdentifiers

struct InstallROMSheet: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var romLibrary: ROMLibrary
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

    @State private var installMode: InstallMode = .file
    @State private var urlText = ""
    @State private var nameText = ""
    @State private var system = "CHIP8"
    @State private var isImporting = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedFileName: String?
    @State private var pendingURL: URL?
    @State private var didInstall = false

    enum InstallMode: String, CaseIterable {
        case file = "File"
        case url = "URL"
    }

    let systems = ["CHIP8", "NDS", "GBA", "GB", "GBC", "NES", "SNES", "N64", "PS1", "Genesis", "SMS", "PSP", "Arcade", "Other"]

    private static let romExtensions = [
        "ch8", "c8",
        "nds", "dsi", "gba", "gb", "gbc", "nes", "fds",
        "sfc", "smc", "n64", "z64", "v64",
        "iso", "bin", "cue", "chd", "pbp",
        "md", "gen", "smd", "sms", "gg",
        "zip", "7z", "rar"
    ]

    private var allowedTypes: [UTType] {
        var types: [UTType] = [.item, .data, .content, .archive, .zip]
        for ext in Self.romExtensions {
            if let t = UTType(filenameExtension: ext) { types.append(t) }
        }
        return types
    }

    var body: some View {
        NavigationStack {
            ZStack {
                settings.backgroundColor.opacity(0.97).ignoresSafeArea()
                Form {
                    Section {
                        Picker("Method", selection: $installMode) {
                            ForEach(InstallMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }.pickerStyle(.segmented)
                    }.listRowBackground(Color.white.opacity(0.06))

                    if installMode == .file {
                        Section {
                            Button {
                                errorMessage = nil
                                isImporting = true
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: "doc.badge.plus").font(.title).foregroundStyle(settings.accentColor)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(selectedFileName == nil ? "Choose ROM / ZIP" : "Change File").font(.headline)
                                        Text(selectedFileName ?? ".ch8  .zip  .nds  .gba  any ROM")
                                            .font(.caption).foregroundStyle(.secondary).lineLimit(2)
                                    }
                                    Spacer()
                                    Image(systemName: "folder.fill").foregroundStyle(settings.accentColor)
                                }.padding(.vertical, 10)
                            }.buttonStyle(.plain)
                        } header: { Text("Select from Files") }
                        footer: { Text("CHIP-8 (.ch8) runs with built-in core + real pixels. Other systems need a core dylib.") }
                        .listRowBackground(Color.white.opacity(0.06))
                    } else {
                        Section("ROM URL") {
                            TextField("https://…/game.ch8", text: $urlText)
                                .textInputAutocapitalization(.never).keyboardType(.URL).autocorrectionDisabled()
                        }.listRowBackground(Color.white.opacity(0.06))
                    }

                    Section("Details") {
                        TextField("Display Name (optional)", text: $nameText)
                        Picker("System", selection: $system) {
                            ForEach(systems, id: \.self) { Text($0).tag($0) }
                        }
                    }.listRowBackground(Color.white.opacity(0.06))

                    if let error = errorMessage {
                        Section { Text(error).foregroundStyle(.red).font(.footnote) }
                            .listRowBackground(Color.white.opacity(0.06))
                    }

                    Section {
                        Button { Task { await doInstall() } } label: {
                            HStack {
                                Spacer()
                                if isLoading { ProgressView() }
                                else { Label("Install", systemImage: "arrow.down.circle.fill").font(.headline) }
                                Spacer()
                            }.padding(.vertical, 6)
                        }
                        .disabled(isLoading || !canInstall)
                        .tint(settings.accentColor)
                    }.listRowBackground(settings.accentColor.opacity(0.18))
                }.scrollContentBackground(.hidden)
            }
            .navigationTitle("Install ROM")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .fileImporter(isPresented: $isImporting, allowedContentTypes: allowedTypes, allowsMultipleSelection: false) { handleImport($0) }
        }
        .presentationDetents([.medium, .large])
        .preferredColorScheme(.dark)
    }

    private var canInstall: Bool {
        if installMode == .url { return !urlText.trimmingCharacters(in: .whitespaces).isEmpty }
        return selectedFileName != nil && pendingURL != nil && !didInstall
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { errorMessage = "No file selected"; return }
            let fileName = url.lastPathComponent
            selectedFileName = fileName
            pendingURL = url
            didInstall = false
            let ext = (fileName as NSString).pathExtension.lowercased()
            if let detected = detectSystem(ext: ext) { system = detected }
            if nameText.isEmpty { nameText = (fileName as NSString).deletingPathExtension }
        case .failure(let err):
            errorMessage = "Picker error: \(err.localizedDescription)"
        }
    }

    private func detectSystem(ext: String) -> String? {
        switch ext {
        case "ch8", "c8": return "CHIP8"
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
        default: return nil
        }
    }

    private func doInstall() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        if installMode == .url {
            do {
                _ = try await romLibrary.addFromURL(urlText.trimmingCharacters(in: .whitespacesAndNewlines), name: nameText.isEmpty ? nil : nameText, system: system)
                dismiss()
            } catch { errorMessage = error.localizedDescription }
            return
        }
        guard let url = pendingURL else { isImporting = true; return }
        let fileName = selectedFileName ?? url.lastPathComponent
        let display = nameText.isEmpty ? (fileName as NSString).deletingPathExtension : nameText
        let game = romLibrary.addGame(name: display, system: system, fileName: fileName, sourceURL: url)
        if game.fileURL == nil {
            errorMessage = romLibrary.lastError ?? "Could not copy file. Try again."
            return
        }
        didInstall = true
        dismiss()
    }
}
