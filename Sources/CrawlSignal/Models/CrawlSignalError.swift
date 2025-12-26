// File: Sources/CrawlSignal/Models/CrawlSignalError.swift
import Foundation

public enum CrawlSignalError: Error, LocalizedError {
    case invalidURL(String)
    case missingAPIKey(String)
    case httpError(status: Int, body: String)
    case decodingError(String)
    case unexpected(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let value):
            return "Invalid URL: \(value)"
        case .missingAPIKey(let context):
            return "Missing API key for \(context). Provide via argument or environment variable."
        case .httpError(let status, let body):
            return "HTTP error (status \(status)): \(body)"
        case .decodingError(let detail):
            return "Failed to decode response: \(detail)"
        case .unexpected(let detail):
            return "Unexpected error: \(detail)"
        }
    }
}
