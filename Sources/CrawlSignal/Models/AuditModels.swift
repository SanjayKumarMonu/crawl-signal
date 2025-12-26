// File: Sources/CrawlSignal/Models/AuditModels.swift
import Foundation

struct ContentSignals: Equatable {
    let mainPresent: Bool
    let articlePresent: Bool
    let h1Present: Bool
    let scriptCount: Int
    let textLength: Int
}

struct AuditReport {
    var criticalIssues: [String]
    var warnings: [String]
    var goodSignals: [String]
    var nextActions: [String]

    func toMarkdown() -> String {
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

enum BotAccess: String {
    case allowed
    case blocked
    case unknown
}

struct BotRobotsStatus {
    let agent: String
    let status: BotAccess
}
