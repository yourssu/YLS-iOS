//
//  YLS.swift
//  YLS-iOS
//
//  Created by 정지혁 on 1/30/24.
//

import Foundation

public final class YLS {
    public static let shared = YLS()

    private var url: URL?

    private init() {}

    public func initialize(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        self.url = url
    }
}
