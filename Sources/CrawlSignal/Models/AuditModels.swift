// File: Sources/CrawlSignal/Models/AuditModels.swift
import Foundation

public struct ContentSignals: Equatable {
    public let mainPresent: Bool
    public let articlePresent: Bool
    public let h1Present: Bool
    public let scriptCount: Int
    public let textLength: Int

    public init(mainPresent: Bool, articlePresent: Bool, h1Present: Bool, scriptCount: Int, textLength: Int) {
        self.mainPresent = mainPresent
        self.articlePresent = articlePresent
        self.h1Present = h1Present
        self.scriptCount = scriptCount
        self.textLength = textLength
    }
}

public struct AuditReport {
    public var criticalIssues: [String]
    public var warnings: [String]
    public var goodSignals: [String]
    public var nextActions: [String]

    public init(criticalIssues: [String], warnings: [String], goodSignals: [String], nextActions: [String]) {
        self.criticalIssues = criticalIssues
        self.warnings = warnings
        self.goodSignals = goodSignals
        self.nextActions = nextActions
    }

    public func toMarkdown() -> String {
        var lines: [String] = []
        lines.append("## Critical issues")
        lines.append(contentsOf: criticalIssues.map { "- \($0)" })

        lines.append("\n## Warnings")
        lines.append(contentsOf: warnings.map { "- \($0)" })

        lines.append("\n## Good signals")
        lines.append(contentsOf: goodSignals.map { "- \($0)" })

        lines.append("\n## Next actions")
        lines.append(contentsOf: nextActions.map { "- \($0)" })

        return lines.joined(separator: "\n")
    }
}

public enum BotAccess: String {
    case allowed
    case blocked
    case unknown
}

public struct BotRobotsStatus {
    public let agent: String
    public let status: BotAccess

    public init(agent: String, status: BotAccess) {
        self.agent = agent
        self.status = status
    }
}
