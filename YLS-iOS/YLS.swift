//
//  YLS.swift
//  YLS-iOS
//
//  Created by 정지혁 on 1/30/24.
//

import Foundation
import OSLog

let logger = Logger(subsystem: "YLS", category: "Logging")

public final class YLS {
    public static let shared = YLS()

    private var url: URL?

    private init() {}

    public func initialize(from urlString: String) {
        guard let url = URL(string: urlString) else {
            logger.error("Failure YLS init by - \(urlString)")
            return
        }
        logger.info("Success YLS init by - \(urlString)")
        self.url = url
    }

    public func logEvent(userID: String, name: String, extra: [String: String]? = nil) {
        guard let url else {
            logger.warning("YLS is not initialized")
            return
        }

        Task {
            let timestamp = ISO8601DateFormatter().string(from: Date())
            var event: [String: String] = ["platform": "iOS", "name": name]
            if let extra {
                event = event.merging(extra) { (current, new) in new }
            }
            let ylsEvent = YLSEvent(userID: userID, timestamp: timestamp, event: event)

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            do {
                let body = try JSONEncoder().encode(ylsEvent)
                request.httpBody = body

                // 테스트용 코드
                try await Task.sleep(nanoseconds: 1_000_000_000)
                logger.info("YLS success to log event - \(String(describing: ylsEvent))")

//                let (_, response) = try await URLSession.shared.data(for: request)
//                if let urlResponse = response as? HTTPURLResponse {
//                    switch urlResponse.statusCode {
//                    case 200..<300:
//                        logger.info("YLS success to log event - \(String(describing: ylsEvent))")
//                    default:
//                        logger.warning("YLS fail to logging - \(urlResponse.statusCode)")
//                    }
//                } else {
//                    logger.warning("YLS fail to logging")
//                }
            } catch {
                logger.error("YLS fail to logging - \(error)")
            }
        }
    }
}
