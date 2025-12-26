// File: Sources/CrawlSignal/Services/AuditorService.swift
import Foundation

actor AuditorService {
    private let session: URLSession
    private let logger: Logger
    private let robotsService: RobotsTxtService

    init(logger: Logger, robotsService: RobotsTxtService) {
        self.logger = logger
        self.robotsService = robotsService
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }

    func audit(urlString: String, checkRobotsTxt: Bool) async -> String {
        guard let url = URL(string: urlString) else {
            return AuditReport(
                criticalIssues: ["Invalid URL: \(urlString)"],
                warnings: [],
                goodSignals: [],
                nextActions: ["Provide a valid URL to audit."]
            ).toMarkdown()
        }

        var critical: [String] = []
        var warnings: [String] = []
        var good: [String] = []
        var nextActions: [String] = []

        var htmlBody = ""
        var headers: [AnyHashable: Any] = [:]

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw CrawlSignalError.unexpected("Non-HTTP response")
            }
            headers = http.allHeaderFields
            htmlBody = String(decoding: data, as: UTF8.self)

            if !(200...299).contains(http.statusCode) {
                critical.append("HTTP status \(http.statusCode) returned for the page.")
            }

            if let contentTypeRaw = headers.first(where: { (key, _) in
                String(describing: key).lowercased() == "content-type"
            })?.value as? String {
                if !contentTypeRaw.lowercased().contains("html") {
                    warnings.append("Content-Type is \(contentTypeRaw), not HTML.")
                }
            }

            let metaDirectives = HTMLParsing.extractMetaDirectives(html: htmlBody)
            if metaDirectives.contains("noindex") { critical.append("Meta robots includes noindex.") }
            if metaDirectives.contains("nofollow") { warnings.append("Meta robots includes nofollow; crawlers may ignore links.") }
            if metaDirectives.contains("nosnippet") { warnings.append("Meta robots includes nosnippet; snippets may be suppressed.") }
            if metaDirectives.contains("noarchive") { warnings.append("Meta robots includes noarchive.") }

            if let xRobots = extractXRobotsTags(headers: headers) {
                if xRobots.contains("noindex") { critical.append("X-Robots-Tag header includes noindex.") }
                if xRobots.contains("nofollow") { warnings.append("X-Robots-Tag header includes nofollow.") }
                if xRobots.contains("nosnippet") { warnings.append("X-Robots-Tag header includes nosnippet.") }
                if xRobots.contains("noarchive") { warnings.append("X-Robots-Tag header includes noarchive.") }
            }

            if let canonical = HTMLParsing.extractCanonical(html: htmlBody) {
                good.append("Canonical tag present: \(canonical)")
            } else {
                warnings.append("No canonical link tag detected.")
                nextActions.append("Add a rel=\"canonical\" tag to declare the preferred URL.")
            }

            let jsonLdCount = HTMLParsing.countJSONLDScripts(html: htmlBody)
            if jsonLdCount > 0 {
                good.append("Found \(jsonLdCount) JSON-LD structured data block(s).")
            } else {
                warnings.append("No JSON-LD structured data detected.")
                nextActions.append("Add JSON-LD structured data to improve entity understanding.")
            }

            let signals = HTMLParsing.detectContentSignals(html: htmlBody)
            if signals.mainPresent { good.append("<main> element detected for primary content.") }
            if signals.articlePresent { good.append("<article> element detected.") }
            if !signals.h1Present { warnings.append("No <h1> heading found; crawlers may lack a clear title.") }
            else { good.append("<h1> heading found.") }

            if signals.scriptCount > 30 && signals.textLength < 800 {
                warnings.append("Page appears script-heavy with limited text; AI crawlers may struggle to extract content.")
                nextActions.append("Reduce reliance on client-side rendering or provide server-rendered fallbacks.")
            }
        } catch {
            critical.append("Failed to fetch page: \(error.localizedDescription)")
            nextActions.append("Verify the URL is reachable and not blocking requests.")
        }

        if checkRobotsTxt, let host = url.host {
            let robots = await robotsService.summarizeAccess(for: host)
            for status in robots {
                switch status.status {
                case .blocked:
                    warnings.append("robots.txt blocks \(status.agent) from the site.")
                    nextActions.append("Update robots.txt to allow \(status.agent) if desired.")
                case .allowed:
                    good.append("robots.txt allows \(status.agent).")
                case .unknown:
                    warnings.append("robots.txt access for \(status.agent) is unknown (no matching group).")
                }
            }
        }

        if critical.isEmpty { critical.append("None noted.") }
        if warnings.isEmpty { warnings.append("None noted.") }
        if good.isEmpty { good.append("No strong positive signals detected yet.") }
        if nextActions.isEmpty { nextActions.append("No immediate actions identified.") }

        let report = AuditReport(criticalIssues: critical, warnings: warnings, goodSignals: good, nextActions: nextActions)
        return report.toMarkdown()
    }

    private func extractXRobotsTags(headers: [AnyHashable: Any]) -> Set<String>? {
        for (key, value) in headers {
            if String(describing: key).lowercased() == "x-robots-tag" {
                if let stringValue = value as? String {
                    let tokens = stringValue.lowercased().split(whereSeparator: { $0 == "," || $0.isWhitespace })
                    return Set(tokens.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
                }
            }
        }
        return nil
    }
}
