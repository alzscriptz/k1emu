import SwiftUI

struct GameInfoSheet: View {
    let game: GameItem
    @EnvironmentObject var romLibrary: ROMLibrary
    @EnvironmentObject var tweakStore: TweakStore
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    private var loadedTweakName: String {
        if let id = game.appliedTweakID,
           let t = tweakStore.tweaks.first(where: { $0.id == id }) {
            return t.name
        }
        return "None"
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Game") {
                    LabeledContent("Name", value: game.name)
                    LabeledContent("System", value: game.displaySystem)
                    LabeledContent("File", value: game.fileName)
                    LabeledContent("Added", value: game.dateAdded.formatted(date: .abbreviated, time: .omitted))
                    if let last = game.lastPlayed {
                        LabeledContent("Last played", value: last.formatted())
                    }
                    LabeledContent("Play count", value: "\(game.playCount)")
                }

                Section("Tweak") {
                    LabeledContent("Loaded", value: loadedTweakName)
                    Button("Change / Load Tweak…") {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            appState.showTweakPickerFor = game
                        }
                    }
                }

                if !game.notes.isEmpty {
                    Section("Notes") {
                        Text(game.notes)
                    }
                }
            }
            .navigationTitle("Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
