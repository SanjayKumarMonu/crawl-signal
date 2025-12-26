// File: Tests/CrawlSignalTests/IndexNowPayloadTests.swift
import XCTest
@testable import CrawlSignal

final class IndexNowPayloadTests: XCTestCase {
    func testPayloadEncoding() throws {
        let payload = IndexNowPayload(host: "example.com", key: "abc123", keyLocation: "https://example.com/abc123.txt", urlList: ["https://example.com/page"])
        let data = try JSONEncoder().encode(payload)
        let json = String(data: data, encoding: .utf8) ?? ""
        XCTAssertTrue(json.contains("\"host\""))
        XCTAssertTrue(json.contains("example.com"))
        XCTAssertTrue(json.contains("urlList"))
    }

    func testHostDerivation() {
        let url = URL(string: "https://example.com/path")!
        XCTAssertEqual(URLValidation.deriveHost(from: url), "example.com")
    }
}
