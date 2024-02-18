//
//  YLSEvent.swift
//
//
//  Created by 정지혁 on 2/15/24.
//

import Foundation

struct YLSEvent {
    let hashedID: String
    let timestamp: String
    let event: [String: Any]

    func fetchDictionary() -> [String: Any] {
        return ["hashedID": hashedID, "timestamp": timestamp, "event": event]
    }
}
