import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct InstallROMSheet: View {
    @EnvironmentObject var romLibrary: ROMLibrary
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

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

    var body: some View {
        NavigationStack {
            ZStack {
                settings.backgroundColor.ignoresSafeArea()

                Form {
                    Section {
                        Picker("Method", selection: $installMode) {
                            ForEach(InstallMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    if installMode == .file {
                        Section {
                            Button {
                                errorMessage = nil
                                selectedFileName = nil
                                isImporting = true
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: "folder.badge.plus")
                                        .font(.title2)
                                        .foregroundStyle(settings.accentColor)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(selectedFileName ?? "Choose a ROM or ZIP")
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text("Files • Downloads • iCloud Drive • On My iPhone")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.tertiary)
                                }
                                .contentShape(Rectangle())
                                .padding(.vertical, 7)
                            }
                            .buttonStyle(.plain)
                        } header: {
                            Text("ROM file")
                        } footer: {
                            Text("ZIP files are opened inside k1emu and the first supported ROM is extracted into your library.")
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
                            ForEach(systems, id: \.self) { item in
                                Text(item).tag(item)
                            }
                        }
                    }

                    if let errorMessage {
                        Section("Error") {
                            Text(errorMessage)
                                .foregroundStyle(.red)
                                .font(.footnote)
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
            .sheet(isPresented: $isImporting) {
                ROMDocumentPicker(
                    onPick: { url in
                        isImporting = false
                        handleImportedURL(url)
                    },
                    onCancel: {
                        isImporting = false
                    }
                )
                .ignoresSafeArea()
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

    private func handleImportedURL(_ url: URL) {
        let access = url.startAccessingSecurityScopedResource()
        defer {
            if access {
                url.stopAccessingSecurityScopedResource()
            }
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

        do {
            _ = try romLibrary.importROM(
                from: url,
                name: nameText.isEmpty ? nil : nameText,
                system: system
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            selectedFileName = nil
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
            if selectedFileName == nil {
                isImporting = true
            }
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

private struct ROMDocumentPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [.item, .data, .zip],
            asCopy: true
        )
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        let onCancel: () -> Void

        init(onPick: @escaping (URL) -> Void, onCancel: @escaping () -> Void) {
            self.onPick = onPick
            self.onCancel = onCancel
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else {
                onCancel()
                return
            }
            onPick(url)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onCancel()
        }
    }
}
