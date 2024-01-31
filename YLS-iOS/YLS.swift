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
    private var userID: String?

    private init() {}

    public func initialize(from urlString: String) {
        guard let url = URL(string: urlString) else {
            logger.error("Failure YLS init by - \(urlString)")
            return
        }
        logger.info("Success YLS init by - \(urlString)")
        self.url = url
    }

    public func setUserID(of userID: String) {
        self.userID = userID
    }

    public func logEvent(name: String, extra: [String: Any] = [:]) {
        guard let url, let userID else {
            logger.warning("YLS should init UserID and URL")
            return
        }

        Task {
            let timestamp = ISO8601DateFormatter().string(from: Date())

            var eventInfo: [String: Any] = ["platform": "iOS", "name": name]
            eventInfo = eventInfo.merging(extra) { (current, new) in new }

            let event: [String: Any] = ["user": userID, "timestamp": timestamp, "event": eventInfo]

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            do {
                let data = try JSONSerialization.data(withJSONObject: event, options: .prettyPrinted)
                request.httpBody = data

                // 테스트용 코드
                try await Task.sleep(nanoseconds: 1_000_000_000)
                logger.info("YLS success to log event - \(String(describing: event))")
                logger.info("YLS log data - \(data)")

//                let (_, response) = try await URLSession.shared.data(for: request)
//                if let urlResponse = response as? HTTPURLResponse {
//                    switch urlResponse.statusCode {
//                    case 200..<300:
//                        logger.info("YLS success to log event - \(String(describing: event))")
//                        logger.info("YLS log data - \(data)")
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

    public func logScreenEvent(screenName name: String, extra: [String: Any] = [:]) {
        logEvent(name: "\(name)Viewed", extra: extra)
    }

    public func logTapEvent(buttonName name: String, extra: [String: Any] = [:]) {
        logEvent(name: "\(name)Tapped", extra: extra)
    }
}
