// File: Tests/CrawlSignalTests/RobotsTxtServiceTests.swift
import XCTest
@testable import CrawlSignal

final class RobotsTxtServiceTests: XCTestCase {
    func testParseAndEvaluate() async throws {
        let logger = Logger.shared
        let service = RobotsTxtService(logger: logger)
        let sample = """
        User-agent: *
        Disallow: /private

        User-agent: claudeBot
        Allow: /
        Disallow: /blocked
        """
        let robots = service.parse(content: sample)
        XCTAssertEqual(robots.groups.count, 2)

        let general = service.evaluateAccess(for: "SomeBot", path: "/private/page", robots: robots)
        XCTAssertEqual(general, .blocked)

        let claude = service.evaluateAccess(for: "ClaudeBot", path: "/blocked/page", robots: robots)
        XCTAssertEqual(claude, .blocked)

        let allowed = service.evaluateAccess(for: "ClaudeBot", path: "/public", robots: robots)
        XCTAssertEqual(allowed, .allowed)
    }
}
