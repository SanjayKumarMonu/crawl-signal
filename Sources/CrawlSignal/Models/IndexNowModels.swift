// File: Sources/CrawlSignal/Models/IndexNowModels.swift
import Foundation

struct IndexNowPayload: Codable, Equatable {
    let host: String
    let key: String
    let keyLocation: String
    let urlList: [String]
}

enum URLValidation {
    static func deriveHost(from url: URL) -> String? {
        return url.host
    }

    static func normalizeURLStrings(_ inputs: [String]) -> [URL] {
        return inputs.compactMap { URL(string: $0) }
    }
}
