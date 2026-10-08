import SwiftUI
import UniformTypeIdentifiers
import UIKit

/// UIDocumentPicker — more reliable than SwiftUI fileImporter on LiveContainer / sideload.
struct DocumentPicker: UIViewControllerRepresentable {
    var onPick: (URL) -> Void
    var onCancel: (() -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // public.item = ANY file (critical for .nds / .zip / unknown UTIs)
        let types: [UTType] = [.item, .data, .content, .archive, .zip]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        // asCopy: true → system copies into app temp; no long-lived security scope needed
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        picker.modalPresentationStyle = .formSheet
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        let onCancel: (() -> Void)?

        init(onPick: @escaping (URL) -> Void, onCancel: (() -> Void)?) {
            self.onPick = onPick
            self.onCancel = onCancel
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onCancel?()
        }
    }
}
