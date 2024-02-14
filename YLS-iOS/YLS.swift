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
    private var caches: [YLSEvent] = []

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
        // 비로그인 처리 + 암호화 진행
        self.userID = userID
    }

    public func logEvent(name: String, extra: [String: Any] = [:]) {
        guard let userID else {
            logger.warning("YLS should init UserID")
            return
        }

        let timestamp = ISO8601DateFormatter().string(from: Date())

        var event: [String: Any] = ["platform": "iOS", "name": name]
        event = event.merging(extra) { (current, new) in new }

        let ylsEvent = YLSEvent(userID: userID, timestamp: timestamp, event: event)
        self.caches.append(ylsEvent)

        if self.caches.count >= 10 {
            flush()
        }
    }

    public func logScreenEvent(screenName name: String, extra: [String: Any] = [:]) {
        logEvent(name: "\(name)Viewed", extra: extra)
    }

    public func logTapEvent(buttonName name: String, extra: [String: Any] = [:]) {
        logEvent(name: "\(name)Tapped", extra: extra)
    }

    public func logLeaveEvent(extra: [String: Any] = [:]) {
        logEvent(name: "User Leaved", extra: extra)
        flush()
    }

    private func flush() {
        guard let url, !self.caches.isEmpty else {
            logger.warning("YLS should init URL")
            return
        }

        Task {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            do {
                let events = self.caches.map { $0.fetchDictionary() }
                self.caches = []
                let data = try JSONSerialization.data(withJSONObject: events, options: .prettyPrinted)
                request.httpBody = data

                // 테스트용 코드
                try await Task.sleep(nanoseconds: 1_000_000_000)
                logger.info("YLS success to log event - \(String(describing: events))")

//                let (_, response) = try await URLSession.shared.data(for: request)
//                if let urlResponse = response as? HTTPURLResponse {
//                    switch urlResponse.statusCode {
//                    case 200..<300:
//                        logger.info("YLS success to log event - \(String(describing: ylsEvent))")
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
}
