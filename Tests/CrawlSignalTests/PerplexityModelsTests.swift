// File: Tests/CrawlSignalTests/PerplexityModelsTests.swift
import XCTest
@testable import CrawlSignal

final class PerplexityModelsTests: XCTestCase {
    func testRequestEncoding() throws {
        let request = PerplexityRequest(model: "sonar-pro", messages: [PerplexityMessage(role: "user", content: "Hello")])
        let data = try JSONEncoder().encode(request)
        let json = String(data: data, encoding: .utf8) ?? ""
        XCTAssertTrue(json.contains("sonar-pro"))
        XCTAssertTrue(json.contains("messages"))
    }
}
