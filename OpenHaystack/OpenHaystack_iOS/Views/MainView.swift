//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import MapKit
import SwiftUI
import os

struct MainView: View {
    @EnvironmentObject var accessoryController: AccessoryController
    var accessories: [Accessory] {
        return self.accessoryController.accessories
    }

    @State var mapType: MKMapType = .standard
    @State var focusedAccessory: Accessory?
    @State var historyMapView = false
    @State var historySeconds: TimeInterval = TimeInterval.Units.day.rawValue
    @State var urlString: String = UserDefaults.standard.urlString ?? ""
    @State var expandAccessories = false
    @State var isLoading = false
    @State var selectedFile: Data?
    @State var showFilePicker = false

    var body: some View {
        ZStack {
            AccessoryMapViewiOS(
                accessoryController: self.accessoryController,
                mapType: $mapType,
                focusedAccessory: $focusedAccessory,
                showHistory: $historyMapView,
                showPastHistory: $historySeconds
            )
            .edgesIgnoringSafeArea(.all)

            self.accessoryListView
                .edgesIgnoringSafeArea(.bottom)
        }
        .sheet(
            isPresented: self.$showFilePicker,
            content: {
                DocumentPickerView(selectedFile: self.$selectedFile)
            }
        )
        .onChange(
            of: self.urlString,
            perform: { value in
                if let url = URL(string: value) {
                    self.accessoryController.findMyController.serverURL = url
                    UserDefaults.standard.urlString = value
                }
            }
        )
        .onChange(
            of: self.selectedFile,
            perform: { optionalFile in
                guard let file = optionalFile else { return }
                //File has been selected
                self.accessoryController.importAccessories(from: file)
            }
        )
        .onAppear {
            if let url = URL(string: self.urlString) {
                self.accessoryController.findMyController.serverURL = url
                self.downloadLocationReports()
            }
        }
    }

    var accessoryListView: some View {
        GeometryReader { geo in
            VStack {

                Button(
                    action: {
                        //Enlarge
                        withAnimation {
                            self.expandAccessories.toggle()
                        }
                    },
                    label: {
                        VStack {
                            Image(systemName: "chevron.compact.up")
                                .resizable()
                                .rotationEffect(self.expandAccessories ? Angle(degrees: 180) : Angle(degrees: 0))
                                .foregroundColor(Color("Button"))
                                .frame(width: 50, height: 15)
                                .contentShape(Rectangle())
                                .padding()
                        }
                    })

                HStack {
                    TextField("Server url", text: $urlString)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .padding(10)

                ZStack {
                    Text("Your accessories")
                        .font(.title2)

                    HStack {

                        Spacer()

                        Button(
                            action: {
                                //Import
                                self.showFilePicker = true
                            },
                            label: {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.title2)
                            }
                        )
                        .padding(8)

                        Button(
                            action: {
                                self.downloadLocationReports()
                            },
                            label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.title2)
                            }
                        )
                        .padding(8)
                    }
                }

                List(self.accessories, id: \.self, selection: self.$focusedAccessory) { accessory in
                    AccessoryListEntryiOS(
                        accessory: accessory,
                        accessoryIcon: Binding(
                            get: { accessory.icon },
                            set: { accessory.icon = $0 }
                        ),
                        accessoryColor: Binding(
                            get: { accessory.color },
                            set: { accessory.color = $0 }
                        ),
                        accessoryName: Binding(
                            get: { accessory.name },
                            set: { accessory.name = $0 }
                        ),
                        delete: { try? self.accessoryController.delete(accessory: $0) },
                        zoomOn: { self.focusedAccessory = $0 })
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 25.0)
                    .fill(Color("Background"))
            )
            .offset(x: 0, y: self.expandAccessories ? 0 : geo.size.height * 0.75)
        }
        .clipped()

    }

    func downloadLocationReports() {
        self.isLoading = true
        self.accessoryController.downloadLocationReports { result in
            self.isLoading = false
            switch result {
            case .failure(let error):
                //TODO: Show error alert
                break
            case .success(_):
                break
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var accessoryController = AccessoryControllerPreview(accessories: PreviewData.accessories, findMyController: FindMyController()) as AccessoryController

    static var previews: some View {
        MainView()
            .environmentObject(self.accessoryController)
    }
}
