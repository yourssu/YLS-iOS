// The Swift Programming Language
// https://docs.swift.org/swift-book

import CryptoKit
import Foundation
import OSLog

let logger = Logger(subsystem: "YLS", category: "Logging")

public final class YLS {
    public static let shared = YLS()

    private var url: URL?
    private var hashedUserID: String?
    private var caches: [YLSEvent] = []

    private init() {}

    /// YLS를 초기화하는 함수입니다.
    /// - Parameter urlString: 해당하는 서비스의 로깅 시스템 URL 문자열
    public func initialize(from urlString: String) {
        guard let url = URL(string: urlString) else {
            logger.error("Failure YLS init by - \(urlString)")
            return
        }
        logger.info("Success YLS init by - \(urlString)")
        self.url = url
    }

    /// YLS에서 사용할 UserID를 설정하는 함수입니다.
    /// - Parameter userID: 로그인된 사용자일 경우에는 UserID, 아닐 경우 nil
    public func setUserID(of userID: String?) {
        if let userID {
            self.hashedUserID = hashUserID(userID: userID)
        } else {
            self.hashedUserID = hashUserID(userID: fetchRandomString(length: 10))
        }
        logger.info("YLS set hashUserID of \(self.hashedUserID ?? "")")
    }

    /// <#Description#>
    /// - Parameters:
    ///   - name: <#name description#>
    ///   - extra: <#extra description#>
    public func logEvent(name: String, extra: [String: Any] = [:]) {
        guard let hashedUserID else {
            logger.warning("YLS should init UserID")
            return
        }

        let timestamp = ISO8601DateFormatter().string(from: Date())

        var event: [String: Any] = ["platform": "iOS", "name": name]
        event = event.merging(extra) { (current, new) in new }

        let ylsEvent = YLSEvent(userID: hashedUserID, timestamp: timestamp, event: event)
        self.caches.append(ylsEvent)

        if self.caches.count >= 10 {
            flush()
        }
    }

    /// <#Description#>
    /// - Parameters:
    ///   - name: <#name description#>
    ///   - extra: <#extra description#>
    public func logScreenEvent(screenName name: String, extra: [String: Any] = [:]) {
        logEvent(name: "\(name)Viewed", extra: extra)
    }

    /// <#Description#>
    /// - Parameters:
    ///   - name: <#name description#>
    ///   - extra: <#extra description#>
    public func logTapEvent(buttonName name: String, extra: [String: Any] = [:]) {
        logEvent(name: "\(name)Tapped", extra: extra)
    }

    /// <#Description#>
    /// - Parameter extra: <#extra description#>
    public func logLeaveEvent(extra: [String: Any] = [:]) {
        logEvent(name: "User Leaved", extra: extra)
        flush()
    }
}

extension YLS {
    func flush() {
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

    func hashUserID(userID: String) -> String {
        let data = userID.data(using: .utf8)!
        let hashedData = SHA256.hash(data: data)
        let hashedString = hashedData.compactMap { String(format: "%02x", $0) }.joined()
        logger.info("YLS hashed userID from \(userID) to \(hashedString)")
        return hashedString
    }

    func fetchRandomString(length: Int) -> String {
        let base = "!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
        return String((0..<length).map { _ in base.randomElement()! })
    }
}
