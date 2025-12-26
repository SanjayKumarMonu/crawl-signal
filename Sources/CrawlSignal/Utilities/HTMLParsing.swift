// File: Sources/CrawlSignal/Utilities/HTMLParsing.swift
import Foundation

enum HTMLParsing {
    static func extractMetaDirectives(html: String) -> Set<String> {
        let lowercased = html.lowercased()
        var results: Set<String> = []
        let pattern = #"<meta[^>]*>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return results
        }
        let range = NSRange(location: 0, length: lowercased.utf16.count)
        let matches = regex.matches(in: lowercased, options: [], range: range)
        for match in matches {
            if let metaRange = Range(match.range, in: lowercased) {
                let tag = String(lowercased[metaRange])
                let attrs = parseAttributes(tag: tag)
                guard let name = attrs["name"]?.trimmingCharacters(in: .whitespacesAndNewlines) else { continue }
                let watchList: Set<String> = ["robots", "googlebot", "bingbot", "perplexitybot", "claudebot"]
                if watchList.contains(name), let content = attrs["content"] {
                    content.split(whereSeparator: { $0 == "," || $0.isWhitespace }).forEach { token in
                        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty { results.insert(trimmed) }
                    }
                }
            }
        }
        return results
    }

    static func extractCanonical(html: String) -> String? {
        let lowercased = html.lowercased()
        let pattern = #"<link[^>]*>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let range = NSRange(location: 0, length: lowercased.utf16.count)
        let matches = regex.matches(in: lowercased, options: [], range: range)
        for match in matches {
            if let tagRange = Range(match.range, in: lowercased) {
                let tag = String(lowercased[tagRange])
                let attrs = parseAttributes(tag: tag)
                if attrs["rel"] == "canonical", let href = attrs["href"], !href.isEmpty {
                    return href
                }
            }
        }
        return nil
    }

    static func countJSONLDScripts(html: String) -> Int {
        let lower = html.lowercased()
        let pattern = #"<script[^>]*type\s*=\s*\"application/ld\+json\"[^>]*>"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        let range = NSRange(location: 0, length: lower.utf16.count)
        let count = regex?.numberOfMatches(in: lower, options: [], range: range) ?? 0
        return count
    }

    static func detectContentSignals(html: String) -> ContentSignals {
        let lower = html.lowercased()
        let mainPresent = lower.contains("<main")
        let articlePresent = lower.contains("<article")
        let h1Present = lower.contains("<h1")

        let scriptPattern = #"<script\b"#
        let scriptRegex = try? NSRegularExpression(pattern: scriptPattern, options: [.caseInsensitive])
        let scriptCount = scriptRegex?.numberOfMatches(in: lower, options: [], range: NSRange(location: 0, length: lower.utf16.count)) ?? 0

        let textOnly = lower.replacingOccurrences(of: #"<[^>]+>"#, with: " ", options: .regularExpression)
        let textLength = textOnly.trimmingCharacters(in: .whitespacesAndNewlines).count

        return ContentSignals(mainPresent: mainPresent, articlePresent: articlePresent, h1Present: h1Present, scriptCount: scriptCount, textLength: textLength)
    }

    private static func parseAttributes(tag: String) -> [String: String] {
        var attributes: [String: String] = [:]
        let pattern = #"([a-zA-Z0-9_-]+)\s*=\s*\"([^\"]*)\""#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return attributes }
        let range = NSRange(location: 0, length: tag.utf16.count)
        regex.enumerateMatches(in: tag, options: [], range: range) { match, _, _ in
            guard let match = match, match.numberOfRanges == 3 else { return }
            if let nameRange = Range(match.range(at: 1), in: tag), let valueRange = Range(match.range(at: 2), in: tag) {
                let name = String(tag[nameRange]).lowercased()
                let value = String(tag[valueRange])
                attributes[name] = value
            }
        }
        return attributes
    }
}
