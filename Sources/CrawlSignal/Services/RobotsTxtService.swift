// File: Sources/CrawlSignalCore/Services/RobotsTxtService.swift
import Foundation

public struct RobotsRule {
    public enum Directive {
        case allow
        case disallow
    }
    public let directive: Directive
    public let path: String

    public init(directive: Directive, path: String) {
        self.directive = directive
        self.path = path
    }
}

public struct RobotsGroup {
    public var agents: [String]
    public var rules: [RobotsRule]

    public init(agents: [String], rules: [RobotsRule]) {
        self.agents = agents
        self.rules = rules
    }
}

public struct RobotsTxt {
    public let groups: [RobotsGroup]

    public init(groups: [RobotsGroup]) {
        self.groups = groups
    }
}

public actor RobotsTxtService {
    private let session: URLSession
    private let logger: Logger

    public init(logger: Logger) {
        self.logger = logger
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }

    public func fetch(host: String) async throws -> String {
        guard let url = URL(string: "https://\(host)/robots.txt") else {
            throw CrawlSignalError.invalidURL("https://\(host)/robots.txt")
        }
        let request = URLRequest(url: url)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw CrawlSignalError.unexpected("Non-HTTP response for robots.txt")
        }
        if http.statusCode >= 400 {
            throw CrawlSignalError.httpError(status: http.statusCode, body: String(decoding: data, as: UTF8.self))
        }
        let body = String(decoding: data, as: UTF8.self)
        await logger.log(level: "debug", "Fetched robots.txt for \(host) with status \(http.statusCode)")
        return body
    }

    public nonisolated func parse(content: String) -> RobotsTxt {
        var groups: [RobotsGroup] = []
        var currentAgents: [String] = []
        var currentRules: [RobotsRule] = []

        func finishGroup() {
            if !currentAgents.isEmpty {
                groups.append(RobotsGroup(agents: currentAgents, rules: currentRules))
            }
            currentAgents = []
            currentRules = []
        }

        for rawLine in content.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") { continue }
            let parts = line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2 else { continue }
            let field = parts[0].trimmingCharacters(in: .whitespaces).lowercased()
            let value = parts[1].trimmingCharacters(in: .whitespaces)

            switch field {
            case "user-agent":
                if !currentAgents.isEmpty && !currentRules.isEmpty {
                    finishGroup()
                }
                currentAgents.append(value.lowercased())
            case "allow":
                if currentAgents.isEmpty { currentAgents = ["*"] }
                currentRules.append(RobotsRule(directive: .allow, path: value))
            case "disallow":
                if currentAgents.isEmpty { currentAgents = ["*"] }
                currentRules.append(RobotsRule(directive: .disallow, path: value))
            default:
                continue
            }
        }

        finishGroup()
        return RobotsTxt(groups: groups)
    }

    public nonisolated func evaluateAccess(for agent: String, path: String, robots: RobotsTxt) -> BotAccess {
        let lowerAgent = agent.lowercased()
        let group = robots.groups.first { $0.agents.contains(lowerAgent) } ?? robots.groups.first { $0.agents.contains("*") }
        guard let selected = group else { return .unknown }

        var bestRule: RobotsRule?
        for rule in selected.rules {
            guard !rule.path.isEmpty else { continue }
            if path.hasPrefix(rule.path) {
                if let existing = bestRule {
                    if rule.path.count > existing.path.count {
                        bestRule = rule
                    }
                } else {
                    bestRule = rule
                }
            }
        }

        guard let finalRule = bestRule else {
            return .allowed
        }

        switch finalRule.directive {
        case .allow:
            return .allowed
        case .disallow:
            return .blocked
        }
    }

    public func summarizeAccess(for host: String) async -> [BotRobotsStatus] {
        let bots = ["ClaudeBot", "GPTBot", "PerplexityBot", "Bingbot"]
        do {
            let content = try await fetch(host: host)
            let parsed = parse(content: content)
            return bots.map { name in
                let status = evaluateAccess(for: name, path: "/", robots: parsed)
                return BotRobotsStatus(agent: name, status: status)
            }
        } catch {
            Task { await logger.log(level: "error", "Robots fetch failed for \(host): \(error)") }
            return bots.map { BotRobotsStatus(agent: $0, status: .unknown) }
        }
    }
}
