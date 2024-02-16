import XCTest
@testable import YLS_iOS

final class YLS_iOSTests: XCTestCase {
    func testExample() throws {
        // XCTest Documentation
        // https://developer.apple.com/documentation/xctest

        // Defining Test Cases and Test Methods
        // https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods
        let shared = YLS.shared

        for _ in 1...100 {
            let random = shared.fetchRandomString(length: 10)
            let randomHashed = shared.hashUserID(userID: random)
            let data = randomHashed.data(using: .utf8)!
            let byteCount = data.count
            XCTAssertEqual(byteCount, 64)
        }
    }
}
