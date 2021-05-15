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
import os
import UniformTypeIdentifiers

struct AccessoryListEntryiOS: View {
    var accessory: Accessory
    @Binding var accessoryIcon: String
    @Binding var accessoryColor: Color
    @Binding var accessoryName: String
    var delete: (Accessory) -> Void
    var zoomOn: (Accessory) -> Void
    let formatter = DateFormatter()
    @State var editingName: Bool = false

    func timestampView() -> some View {
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return Group {
            if let timestamp = accessory.locationTimestamp {
                Text(formatter.string(from: timestamp))
            } else {
                Text("No location found")
            }
        }
        .font(.footnote)
    }

    var body: some View {

        Button(
            action: {
                self.zoomOn(self.accessory)
            },
            label: {
                HStack {
                    IconSelectionView(selectedImageName: $accessoryIcon, selectedColor: $accessoryColor)

                    VStack(alignment: .leading) {
                        if self.editingName {
                            TextField("Enter accessory name", text: $accessoryName, onCommit: { self.editingName = false })
                                .font(.headline)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        } else {
                            Text(accessory.name)
                                .font(.headline)
                        }
                        self.timestampView()
                    }

                    Spacer()
                    Circle()
                        .fill(accessory.isNearby ? Color.green : accessory.isActive ? Color.orange : Color.red)
                        .frame(width: 8, height: 8)
                }
                .contentShape(Rectangle())
            }
        )
        .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
        .contextMenu {
            Button("Delete", action: { self.delete(accessory) })
            Divider()
            Button("Rename", action: { self.editingName = true })
            Divider()
            Button("Copy key ID (Base64)", action: { self.copyPublicKeyHash(of: accessory) })
            Menu("Copy advertisement key") {
                Button("Base64", action: { self.copyAdvertisementKey(of: accessory) })
                Button("Byte array", action: { self.copyAdvertisementKey(escapedString: false) })
                Button("Escaped string", action: { self.copyAdvertisementKey(escapedString: true) })
            }
            Divider()
        }
    }

    func copyAdvertisementKey(of accessory: Accessory) {
        do {
            let publicKey = try accessory.getAdvertisementKey()
            let pasteboard = UIPasteboard.general
            pasteboard.setValue(publicKey.base64EncodedString(), forPasteboardType: UTType.plainText.identifier)
        } catch {
            os_log("Failed extracing public key %@", String(describing: error))
            assert(false)
        }
    }

    func copyPublicKeyHash(of accessory: Accessory) {
        do {
            let keyID = try accessory.getKeyId()
            let pasteboard = UIPasteboard.general
            pasteboard.setValue(keyID, forPasteboardType: UTType.plainText.identifier)
        } catch {
            os_log("Failed extracing public key %@", String(describing: error))
            assert(false)
        }
    }

    func copyAdvertisementKey(escapedString: Bool) {
        do {
            let publicKey = try self.accessory.getActualPublicKey()
            let keyByteArray = [UInt8](publicKey)

            if escapedString {
                let string = keyByteArray.map { "\\x\(String($0, radix: 16))" }.joined()
                let pasteboard = UIPasteboard.general
                pasteboard.setValue(string, forPasteboardType: UTType.plainText.identifier)
                
            } else {
                let string = keyByteArray.map { "0x\(String($0, radix: 16))" }.joined(separator: ", ")
                let pasteboard = UIPasteboard.general
                pasteboard.setValue(string, forPasteboardType: UTType.plainText.identifier)
            }
        } catch {
            os_log("Failed extracing public key %@", String(describing: error))
            assert(false)
        }
    }
}
