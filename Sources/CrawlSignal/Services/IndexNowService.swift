// File: Sources/CrawlSignalCore/Services/IndexNowService.swift
import Foundation

public actor IndexNowService {
    private let session: URLSession
    private let logger: Logger

    public init(logger: Logger) {
        self.logger = logger
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }

    public func submit(urlStrings: [String], host: String?, apiKey: String?, keyLocation: String?) async throws -> String {
        let urls = URLValidation.normalizeURLStrings(urlStrings)
        guard !urls.isEmpty else { throw CrawlSignalError.invalidURL("No valid URLs provided") }

        let resolvedHost = host ?? urls.first?.host
        guard let finalHost = resolvedHost else { throw CrawlSignalError.invalidURL("Missing host; unable to derive from URL") }

        let resolvedKey: String
        if let apiKey = apiKey, !apiKey.isEmpty {
            resolvedKey = apiKey
        } else if let env = ProcessInfo.processInfo.environment["INDEXNOW_KEY"], !env.isEmpty {
            resolvedKey = env
        } else {
            throw CrawlSignalError.missingAPIKey("IndexNow")
        }

        let resolvedKeyLocation: String
        if let provided = keyLocation, !provided.isEmpty {
            resolvedKeyLocation = provided
        } else if let envLoc = ProcessInfo.processInfo.environment["INDEXNOW_KEY_LOCATION"], !envLoc.isEmpty {
            resolvedKeyLocation = envLoc
        } else {
            resolvedKeyLocation = "https://\(finalHost)/\(resolvedKey).txt"
        }

        let payload = IndexNowPayload(host: finalHost, key: resolvedKey, keyLocation: resolvedKeyLocation, urlList: urls.map { $0.absoluteString })
        return try await send(payload: payload)
    }

    private func send(payload: IndexNowPayload) async throws -> String {
        guard let url = URL(string: "https://api.indexnow.org/indexnow") else {
            throw CrawlSignalError.invalidURL("https://api.indexnow.org/indexnow")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)

        let maxRetries = 4
        var attempt = 0
        var lastStatus = 0
        var lastBody = ""

        while attempt <= maxRetries {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw CrawlSignalError.unexpected("Non-HTTP response from IndexNow")
            }
            lastStatus = http.statusCode
            lastBody = String(decoding: data, as: UTF8.self)

            if http.statusCode == 429 && attempt < maxRetries {
                let backoff = UInt64(pow(2.0, Double(attempt)))
                await logger.log(level: "warning", "IndexNow rate limited (attempt \(attempt + 1)). Backing off for \(backoff)s")
                try await Task.sleep(nanoseconds: backoff * 1_000_000_000)
                attempt += 1
                continue
            }

            if (200...299).contains(http.statusCode) {
                await logger.log(level: "info", "IndexNow submission succeeded with status \(http.statusCode)")
                return "Submitted \(payload.urlList.count) URLs to IndexNow (status \(http.statusCode))."
            }

            break
        }

        await logger.log(level: "error", "IndexNow submission failed: status \(lastStatus) body: \(lastBody.prefix(200))")
        throw CrawlSignalError.httpError(status: lastStatus, body: String(lastBody.prefix(500)))
    }
}
