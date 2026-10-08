import SwiftUI
import UniformTypeIdentifiers

struct InstallROMSheet: View {
    @EnvironmentObject var romLibrary: ROMLibrary
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

    @State private var installMode: InstallMode = .file
    @State private var urlText = ""
    @State private var nameText = ""
    @State private var system = "CHIP8"
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedFileName: String?
    @State private var showPicker = false

    enum InstallMode: String, CaseIterable {
        case file = "File"
        case url = "URL"
        case scan = "Scan"
    }

    let systems = ["CHIP8", "NDS", "GBA", "GB", "GBC", "NES", "SNES", "N64", "PS1", "Genesis", "SMS", "PSP", "Arcade", "Other"]

    var body: some View {
        NavigationStack {
            ZStack {
                settings.backgroundColor.opacity(0.97).ignoresSafeArea()

                Form {
                    Section {
                        Picker("Method", selection: $installMode) {
                            ForEach(InstallMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }
                    .listRowBackground(Color.white.opacity(0.06))

                    if installMode == .file {
                        Section {
                            Button {
                                errorMessage = nil
                                showPicker = true
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: "doc.badge.plus")
                                        .font(.title)
                                        .foregroundStyle(settings.accentColor)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(selectedFileName == nil ? "Choose ROM / ZIP" : "Change File")
                                            .font(.headline)
                                        Text(selectedFileName ?? ".ch8 .zip .nds .gba .nes — any file")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                    Spacer()
                                    Image(systemName: "folder.fill")
                                        .foregroundStyle(settings.accentColor)
                                }
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)
                        } header: {
                            Text("Files / iCloud")
                        } footer: {
                            Text("Uses system document picker with asCopy — works on LiveContainer.")
                        }
                        .listRowBackground(Color.white.opacity(0.06))
                    } else if installMode == .url {
                        Section("ROM URL") {
                            TextField("https://…/game.zip", text: $urlText)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.URL)
                                .autocorrectionDisabled()
                        }
                        .listRowBackground(Color.white.opacity(0.06))
                    } else {
                        Section {
                            Text("Scans On My iPhone → k1emu Documents for ROMs you dropped via Files / Finder / iTunes File Sharing.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Button {
                                romLibrary.scanDocumentsForROMs()
                                dismiss()
                            } label: {
                                Label("Scan Now", systemImage: "arrow.clockwise")
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.06))
                    }

                    if installMode != .scan {
                        Section("Details") {
                            TextField("Display Name (optional)", text: $nameText)
                            Picker("System", selection: $system) {
                                ForEach(systems, id: \.self) { Text($0).tag($0) }
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.06))
                    }

                    if let error = errorMessage {
                        Section {
                            Text(error).foregroundStyle(.red).font(.footnote)
                        }
                        .listRowBackground(Color.white.opacity(0.06))
                    }

                    if installMode != .scan {
                        Section {
                            Button {
                                Task { await doInstall() }
                            } label: {
                                HStack {
                                    Spacer()
                                    if isLoading { ProgressView() }
                                    else { Label("Install", systemImage: "arrow.down.circle.fill").font(.headline) }
                                    Spacer()
                                }
                                .padding(.vertical, 6)
                            }
                            .disabled(isLoading || !canInstall)
                            .tint(settings.accentColor)
                        }
                        .listRowBackground(settings.accentColor.opacity(0.18))
                    }
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
            .sheet(isPresented: $showPicker) {
                DocumentPicker(
                    onPick: { url in
                        showPicker = false
                        handlePicked(url)
                    },
                    onCancel: { showPicker = false }
                )
                .ignoresSafeArea()
            }
        }
        .presentationDetents([.medium, .large])
        .preferredColorScheme(.dark)
    }

    private var canInstall: Bool {
        if installMode == .url {
            return !urlText.trimmingCharacters(in: .whitespaces).isEmpty
        }
        return selectedFileName != nil
    }

    private func handlePicked(_ url: URL) {
        let fileName = url.lastPathComponent
        selectedFileName = fileName
        let ext = (fileName as NSString).pathExtension.lowercased()
        if let detected = ROMLibrary.detectSystem(ext: ext) {
            system = detected
        }
        if nameText.isEmpty {
            nameText = (fileName as NSString).deletingPathExtension
        }

        // Import immediately (asCopy means file is already in app sandbox)
        isLoading = true
        defer { isLoading = false }

        let display = nameText.isEmpty ? (fileName as NSString).deletingPathExtension : nameText
        if let game = romLibrary.importFile(from: url, name: display, system: system) {
            _ = game
            dismiss()
        } else {
            errorMessage = romLibrary.lastError ?? "Import failed"
        }
    }

    private func doInstall() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        if installMode == .url {
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
            return
        }

        // File mode without pending pick → open picker
        if selectedFileName == nil {
            showPicker = true
        }
    }
}
