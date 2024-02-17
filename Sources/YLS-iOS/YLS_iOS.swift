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

    /**
     YLS를 초기화하는 함수입니다.
     
     앱 초기화 시에 로깅 시스템에 해당하는 URL을 설정하는 함수입니다.
     SwiftUI의 경우, App 내부 init() 함수에서
     ```
     init() {
        YLS.shared.initialize(from: "https://www.example.com/"
     }
     ```
     UIKit의 경우, AppDelegate 내부 application() 함수에서
     ```
     func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: ...) -> Bool {
        YLS.shared.initialize(from: "https://www.example.com/"
     }
     ```
     초기화 함수를 호출해주세요
     - Parameter urlString: URL 문자열
     */
    public func initialize(from urlString: String) {
        guard let url = URL(string: urlString) else {
            logger.error("Failure YLS init by - \(urlString)")
            return
        }
        logger.info("Success YLS init by - \(urlString)")
        self.url = url
    }

    /**
     YLS에서 사용할 UserID를 설정하는 함수입니다.
     
     UserID가 확인되는 시점에 호출해주세요.
     로그인이 안된 사용자의 경우, nil을 넘겨주시면 됩니다.
     ```
     YLS.shared.setUserID(of: userID)
     ```
     - Parameter userID: 로그인된 사용자일 경우에는 UserID, 아닐 경우 nil
     */
    public func setUserID(of userID: String?) {
        if let userID {
            self.hashedUserID = hashUserID(userID: userID)
        } else {
            self.hashedUserID = hashUserID(userID: fetchRandomString(length: 10))
        }
        logger.info("YLS set hashUserID of \(self.hashedUserID ?? "")")
    }

    /**
     기본적인 이벤트 로그를 남기는 함수입니다.
     
     화면이나 버튼이 아닌 다른 이벤트의 로그를 남기고 싶을 때 사용하는 함수입니다.
     name에 들어간 이벤트 이름이 그대로 서버에 저장됩니다.
     - Parameters:
        - name: 이벤트 이름
        - extra: 추가적인 정보
     */
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

    /**
     화면 이벤트 로그를 남기는 함수입니다.
     
     현재 화면을 사용자가 보았다는 로그를 남기는 함수입니다.
     SwiftUI의 경우, ViewModifier의 .onAppear()에서,
     ```
     .onAppear {
         YLS.shared.logScreenEvent(screenName: "ContentView")
     }
     ```
     UIkit의 경우, viewDidAppear()에서
     ```
     ```
     호출하는 것을 의도했습니다.
     - Parameters:
        - name: 화면 이름
        - extra: 추가적인 정보
     */
    public func logScreenEvent(screenName name: String, extra: [String: Any] = [:]) {
        logEvent(name: "\(name)Viewed", extra: extra)
    }

    /**
     버튼 터치 이벤트 로그를 남기는 함수입니다.
     
     사용자가 버튼을 눌렀다는 로그를 남기는 함수입니다.
     SwiftUI, UIkit 모두 버튼의 터치 이벤트 내부에서 호출하는 것을 의도했습니다.
     - Parameters:
        - name: 버튼 이름
        - extra: 추가적인 정보
     */
    public func logTapEvent(buttonName name: String, extra: [String: Any] = [:]) {
        logEvent(name: "\(name)Tapped", extra: extra)
    }

    /**
     사용자 이탈 로그를 남기는 함수입니다.
     
     사용자가 앱을 종료하거나 기타 의도된 이탈의 로그를 남기는 함수입니다.
     앱을 종료할 때는, AppDelegate 내부의 applicationWillTerminate()에서 호출하는 것을 의도했습니다.
     ```
     func applicationWillTerminate(_ application: UIApplication) {
        YLS.shared.logLeaveEvent()
        sleep(2)
     }
     ```
     - Parameter extra: 추가적인 정보
     */
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
