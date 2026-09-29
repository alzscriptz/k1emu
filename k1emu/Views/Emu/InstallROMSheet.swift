import SwiftUI
import UniformTypeIdentifiers

struct InstallROMSheet: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var romLibrary: ROMLibrary
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

    @State private var installMode: InstallMode = .file
    @State private var urlText: String = ""
    @State private var nameText: String = ""
    @State private var system: String = "NES"
    @State private var isImporting = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedFileName: String?

    enum InstallMode: String, CaseIterable {
        case file = "File"
        case url = "URL"
    }

    let systems = ["NES", "SNES", "N64", "GB", "GBC", "GBA", "PS1", "NDS", "Genesis", "SMS", "PCE", "Other"]

    // Broad types so ROMs of any extension can be picked
    private var romTypes: [UTType] {
        var types: [UTType] = [.data, .item, .content, .unixExecutable]
        if let zip = UTType(filenameExtension: "zip") { types.append(zip) }
        if let seven = UTType(filenameExtension: "7z") { types.append(seven) }
        for ext in ["nes", "sfc", "smc", "n64", "z64", "v64", "gb", "gbc", "gba", "nds", "iso", "bin", "cue", "chd", "md", "gen", "sms", "gg", "pce"] {
            if let t = UTType(filenameExtension: ext) { types.append(t) }
        }
        return types
    }

    var body: some View {
        NavigationStack {
            ZStack {
                settings.backgroundColor.opacity(0.95).ignoresSafeArea()

                Form {
                    Section {
                        Picker("Method", selection: $installMode) {
                            ForEach(InstallMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .listRowBackground(Color.white.opacity(0.06))

                    if installMode == .url {
                        Section("ROM URL") {
                            TextField("https://…/game.nes", text: $urlText)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.URL)
                                .autocorrectionDisabled()
                        }
                        .listRowBackground(Color.white.opacity(0.06))
                    } else {
                        Section {
                            Button {
                                isImporting = true
                            } label: {
                                HStack {
                                    Image(systemName: "doc.badge.plus")
                                        .font(.title2)
                                        .foregroundStyle(settings.accentColor)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(selectedFileName == nil ? "Choose ROM File" : "Change File")
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text(selectedFileName ?? "Any ROM · ZIP · ISO supported")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                        }
                        .listRowBackground(Color.white.opacity(0.06))
                    }

                    Section("Details") {
                        TextField("Display Name (optional)", text: $nameText)
                        Picker("System", selection: $system) {
                            ForEach(systems, id: \.self) { s in
                                Text(s).tag(s)
                            }
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.06))

                    if let error = errorMessage {
                        Section {
                            Text(error).foregroundStyle(.red)
                        }
                        .listRowBackground(Color.white.opacity(0.06))
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
                                    Label("Install", systemImage: "arrow.down.circle.fill")
                                        .font(.headline)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                        .disabled(isLoading || (installMode == .url && urlText.isEmpty) || (installMode == .file && selectedFileName == nil && !isImporting))
                        .tint(settings.accentColor)
                    }
                    .listRowBackground(settings.accentColor.opacity(0.2))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Install ROM")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: romTypes,
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    let access = url.startAccessingSecurityScopedResource()
                    defer { if access { url.stopAccessingSecurityScopedResource() } }

                    let fileName = url.lastPathComponent
                    selectedFileName = fileName
                    let displayName = nameText.isEmpty ? (fileName as NSString).deletingPathExtension : nameText

                    // Auto-detect system from extension
                    let ext = (fileName as NSString).pathExtension.lowercased()
                    system = detectSystem(ext: ext) ?? system

                    _ = romLibrary.addGame(name: displayName, system: system, fileName: fileName, sourceURL: url)
                    dismiss()
                case .failure(let err):
                    errorMessage = err.localizedDescription
                }
            }
        }
        .presentationDetents([.medium, .large])
        .preferredColorScheme(.dark)
    }

    private func detectSystem(ext: String) -> String? {
        switch ext {
        case "nes", "fds": return "NES"
        case "sfc", "smc": return "SNES"
        case "n64", "z64", "v64": return "N64"
        case "gb": return "GB"
        case "gbc": return "GBC"
        case "gba": return "GBA"
        case "nds": return "NDS"
        case "iso", "bin", "cue", "chd", "pbp": return "PS1"
        case "md", "gen", "smd": return "Genesis"
        case "sms": return "SMS"
        case "pce": return "PCE"
        default: return nil
        }
    }

    private func install() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            if installMode == .url {
                _ = try await romLibrary.addFromURL(urlText, name: nameText.isEmpty ? nil : nameText, system: system)
                dismiss()
            } else {
                // File mode installs via fileImporter callback
                isImporting = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
