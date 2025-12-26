// File: Sources/CrawlSignal/Services/PerplexityService.swift
import Foundation

actor PerplexityService {
    private let session: URLSession
    private let logger: Logger

    init(logger: Logger) {
        self.logger = logger
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }

    func check(urlString: String, apiKey: String?, model: String?) async throws -> String {
        guard let url = URL(string: urlString) else {
            throw CrawlSignalError.invalidURL(urlString)
        }

        let resolvedKey: String
        if let key = apiKey, !key.isEmpty {
            resolvedKey = key
        } else if let env = ProcessInfo.processInfo.environment["PERPLEXITY_API_KEY"], !env.isEmpty {
            resolvedKey = env
        } else {
            throw CrawlSignalError.missingAPIKey("Perplexity")
        }

        let resolvedModel = (model?.isEmpty == false ? model! : nil) ?? ProcessInfo.processInfo.environment["PERPLEXITY_MODEL"] ?? "sonar-pro"

        let prompt = "Access and summarize this URL, explicitly noting if access fails (robots, paywall, 404, or blocked crawler). URL: \(url.absoluteString). Include whether the content was retrievable."
        let body = PerplexityRequest(
            model: resolvedModel,
            messages: [PerplexityMessage(role: "user", content: prompt)]
        )

        guard let endpoint = URL(string: "https://api.perplexity.ai/chat/completions") else {
            throw CrawlSignalError.invalidURL("https://api.perplexity.ai/chat/completions")
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(resolvedKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw CrawlSignalError.unexpected("Non-HTTP response from Perplexity")
        }

        if !(200...299).contains(http.statusCode) {
            let snippet = String(decoding: data, as: UTF8.self)
            await logger.log(level: "error", "Perplexity call failed (status \(http.statusCode)): \(snippet.prefix(200))")
            throw CrawlSignalError.httpError(status: http.statusCode, body: String(snippet.prefix(500)))
        }

        do {
            let decoded = try JSONDecoder().decode(PerplexityResponse.self, from: data)
            if let choice = decoded.choices.first {
                return choice.message.content
            }
            throw CrawlSignalError.decodingError("No choices returned")
        } catch {
            throw CrawlSignalError.decodingError(error.localizedDescription)
        }
    }
}
