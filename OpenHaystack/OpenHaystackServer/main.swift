//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//

import AppKit
import Foundation
import Vapor

let macApp = NSApplication.shared

class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            let app = try Application(.detect())
            defer { app.shutdown() }

            //Routes
            app.post("getLocationReports") { req -> EventLoopFuture<Response> in
                let reportIds = try req.content.decode(GetReportsBody.self)
                print("Received report ids")
                return ServerReportsFetcher.fetchReports(for: reportIds.ids, with: req)
            }

            try app.run()
        } catch {
            fatalError("Vapor failed to start \(String(describing: error))")
        }
    }
}

let delegate = AppDelegate()
macApp.delegate = delegate
macApp.run()
