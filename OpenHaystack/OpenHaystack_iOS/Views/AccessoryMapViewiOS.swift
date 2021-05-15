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

struct AccessoryMapViewiOS: UIViewControllerRepresentable {
    @ObservedObject var accessoryController: AccessoryController
    @Binding var mapType: MKMapType
    @Binding var focusedAccessory: Accessory?
    @Binding var showHistory: Bool
    @Binding var showPastHistory: TimeInterval
    var delayer = UpdateDelayer()

    func makeUIViewController(context: Context) -> AccessoryMapViewController {
        return AccessoryMapViewController()
    }

    func updateUIViewController(_ uiViewController: AccessoryMapViewController, context: Context) {
        let accessories = self.accessoryController.accessories

        uiViewController.focusedAccessory = focusedAccessory
        if showHistory {
            delayer.delayUpdate {
                uiViewController.addAllLocations(from: focusedAccessory!, past: showPastHistory)
                uiViewController.zoomInOnAll()
            }
        } else {
            uiViewController.addLastLocations(from: accessories)
            uiViewController.zoomInOnSelection()
        }
        uiViewController.changeMapType(mapType)
    }
}

final class AccessoryMapViewController: UIViewController, MKMapViewDelegate {
    var mapView: MKMapView = MKMapView()
    var pinsShown = false
    var focusedAccessory: Accessory?

    override func viewDidLoad() {
        self.view.addSubview(mapView)

        self.mapView.delegate = self
        self.mapView.register(AccessoryAnnotationView.self, forAnnotationViewWithReuseIdentifier: "Accessory")
        self.mapView.register(MKPinAnnotationView.self, forAnnotationViewWithReuseIdentifier: "AccessoryHistory")
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.mapView.frame = self.view.bounds
    }

    func addLastLocations(from accessories: [Accessory]) {
        // Add pins
        self.mapView.removeAnnotations(self.mapView.annotations)
        for accessory in accessories {
            guard accessory.lastLocation != nil else { continue }
            let annotation = AccessoryAnnotation(accessory: accessory)
            self.mapView.addAnnotation(annotation)
        }
    }

    func zoomInOnSelection() {
        if focusedAccessory == nil {
            zoomInOnAll()
        } else {
            // Show focused accessory
            let focusedAnnotation: MKAnnotation? = self.mapView.annotations.first(where: { annotation in
                let accessoryAnnotation = annotation as! AccessoryAnnotation
                return accessoryAnnotation.accessory == self.focusedAccessory
            })
            if let annotation = focusedAnnotation {
                zoomInOn(annotations: [annotation])
            }
        }
    }

    func zoomInOnAll() {
        zoomInOn(annotations: self.mapView.annotations)
    }

    func zoomInOn(annotations: [MKAnnotation]) {
        DispatchQueue.main.async {
            self.mapView.showAnnotations(annotations, animated: true)
        }
    }

    func changeMapType(_ mapType: MKMapType) {
        guard self.mapView.mapType != mapType else { return }
        self.mapView.mapType = mapType
    }

    func addAllLocations(from accessory: Accessory, past: TimeInterval) {
        let now = Date()
        let pastLocations = accessory.locations?.filter { location in
            guard let timestamp = location.timestamp else {
                return false
            }
            return timestamp + past >= now
        }

        self.mapView.removeAnnotations(self.mapView.annotations)
        for location in pastLocations ?? [] {
            let coordinate = CLLocationCoordinate2DMake(location.latitude, location.longitude)
            let annotation = AccessoryHistoryAnnotation(coordinate: coordinate)
            self.mapView.addAnnotation(annotation)
        }
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        switch annotation {
        case is AccessoryAnnotation:
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "Accessory", for: annotation)
            annotationView.annotation = annotation
            return annotationView
        case is AccessoryHistoryAnnotation:
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "AccessoryHistory", for: annotation)
            annotationView.annotation = annotation
            return annotationView
        default:
            return nil
        }
    }
}

class UpdateDelayer {
    /// Some view updates need to be delayed to mitigate UI glitches.
    var delayedWorkItem: DispatchWorkItem?

    func delayUpdate(delay: Double = 0.3, closure: @escaping () -> Void) {
        self.delayedWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            closure()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        self.delayedWorkItem = workItem
    }
}
