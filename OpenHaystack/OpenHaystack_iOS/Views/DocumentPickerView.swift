//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct DocumentPickerView: UIViewControllerRepresentable {

    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedFile: Data?

    func makeCoordinator() -> DocumentPickerDelegate {
        return DocumentPickerDelegate(presentationMode: self.presentationMode, selectedFile: $selectedFile)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.propertyList], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        uiViewController.delegate = context.coordinator
        context.coordinator.presentationMode = self.presentationMode
    }
}

class DocumentPickerDelegate: NSObject, ObservableObject, UIDocumentPickerDelegate {
    var presentationMode: Binding<PresentationMode>
    var selectedFile: Binding<Data?>

    internal init(presentationMode: Binding<PresentationMode>, selectedFile: Binding<Data?>) {
        self.presentationMode = presentationMode
        self.selectedFile = selectedFile
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        //Close
        self.presentationMode.wrappedValue.dismiss()
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        self.presentationMode.wrappedValue.dismiss()
        if let url = urls.first {
            _ = url.startAccessingSecurityScopedResource()
            let file = try? Data(contentsOf: url)
            url.stopAccessingSecurityScopedResource()

            if let plistFile = file {
                self.selectedFile.wrappedValue = plistFile
            }
        }
    }
}
