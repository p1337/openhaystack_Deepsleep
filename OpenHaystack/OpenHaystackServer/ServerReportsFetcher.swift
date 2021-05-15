//
//  OpenHaystack – Tracking personal Bluetooth devices via Apple's Find My network
//
//  Copyright © 2021 Secure Mobile Networking Lab (SEEMOO)
//  Copyright © 2021 The Open Wireless Link Project
//
//  SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import Vapor

struct ServerReportsFetcher {
    static func fetchReports(for ids: [String], with req: Request) -> EventLoopFuture<Response> {

        let promise = req.eventLoop.makePromise(of: Response.self)
        var finished = false

        let reportsFetcher = ReportsFetcher()

        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 20) {
            guard !finished else { return }
            promise.succeed(Response(status: .notFound, body: Response.Body(staticString: "Search party token not available")))
        }

        //Get the anisette data and token
        AnisetteDataManager.shared.requestAnisetteData { result in
            switch result {
            case .failure(let error):
                print(error)
                finished = true
                promise.succeed(Response(status: .notFound, body: Response.Body(staticString: "Anisette data not available")))

            case .success(let accountData):
                //Fetch the reports
                guard let token = accountData.searchPartyToken,
                    token.isEmpty == false
                else {
                    finished = true
                    promise.succeed(Response(status: .notFound, body: Response.Body(staticString: "Search party token not available")))
                    return
                }

                // 7 days
                let duration: Double = (24 * 60 * 60) * 7
                let startDate = Date() - duration
                reportsFetcher.query(
                    forHashes: ids,
                    start: startDate,
                    duration: duration,
                    searchPartyToken: token
                ) { responseData in
                    finished = true
                    promise.succeed(Response(status: .ok, body: Response.Body(data: responseData ?? Data())))
                }

            }
        }

        return promise.futureResult
    }
}
