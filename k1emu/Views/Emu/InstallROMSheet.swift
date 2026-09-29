import SwiftUI
import UniformTypeIdentifiers

struct InstallROMSheet: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var romLibrary: ROMLibrary
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

    @State private var installMode: InstallMode = .url
    @State private var urlText: String = ""
    @State private var nameText: String = ""
    @State private var system: String = "NES"
    @State private var isImporting = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    enum InstallMode: String, CaseIterable {
        case url = "Install URL"
        case file = "Install File"
    }

    let systems = ["NES", "SNES", "N64", "GB", "GBC", "GBA", "PS1", "NDS", "Genesis", "SMS", "PCE", "Other"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Method", selection: $installMode) {
                        ForEach(InstallMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if installMode == .url {
                    Section("ROM URL") {
                        TextField("https://example.com/game.nes", text: $urlText)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                    }
                } else {
                    Section {
                        Button {
                            isImporting = true
                        } label: {
                            Label("Choose File…", systemImage: "folder")
                        }
                    }
                }

                Section("Details") {
                    TextField("Display Name (optional)", text: $nameText)
                    Picker("System", selection: $system) {
                        ForEach(systems, id: \.self) { s in
                            Text(s).tag(s)
                        }
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
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
                                Text("Install")
                                    .bold()
                            }
                            Spacer()
                        }
                    }
                    .disabled(isLoading || (installMode == .url && urlText.isEmpty))
                }
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
                allowedContentTypes: [.data, .item],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    let access = url.startAccessingSecurityScopedResource()
                    defer { if access { url.stopAccessingSecurityScopedResource() } }
                    let fileName = url.lastPathComponent
                    let displayName = nameText.isEmpty ? fileName : nameText
                    _ = romLibrary.addGame(name: displayName, system: system, fileName: fileName, sourceURL: url)
                    dismiss()
                case .failure(let err):
                    errorMessage = err.localizedDescription
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func install() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            if installMode == .url {
                _ = try await romLibrary.addFromURL(urlText, name: nameText.isEmpty ? nil : nameText, system: system)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
