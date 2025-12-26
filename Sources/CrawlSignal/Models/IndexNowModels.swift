// File: Sources/CrawlSignal/Models/IndexNowModels.swift
import Foundation

public struct IndexNowPayload: Codable, Equatable {
    public let host: String
    public let key: String
    public let keyLocation: String
    public let urlList: [String]

    public init(host: String, key: String, keyLocation: String, urlList: [String]) {
        self.host = host
        self.key = key
        self.keyLocation = keyLocation
        self.urlList = urlList
    }
}

public enum URLValidation {
    public static func deriveHost(from url: URL) -> String? {
        return url.host
    }

    public static func normalizeURLStrings(_ inputs: [String]) -> [URL] {
        return inputs.compactMap { URL(string: $0) }
    }
}
