//
//  YLSEvent.swift
//  YLS-iOS
//
//  Created by 정지혁 on 2/5/24.
//

import Foundation

struct YLSEvent {
    let userID: String
    let timestamp: String
    let event: [String: Any]

    func fetchDictionary() -> [String: Any] {
        return ["user": userID, "timestamp": timestamp, "event": event]
    }
}
