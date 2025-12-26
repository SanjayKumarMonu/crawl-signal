// File: Tests/CrawlSignalTests/HTMLParsingTests.swift
import XCTest
@testable import CrawlSignal

final class HTMLParsingTests: XCTestCase {
    func testMetaExtraction() {
        let html = """
        <html><head>
        <meta name=\"robots\" content=\"noindex, nofollow\">
        <meta name=\"googlebot\" content=\"nosnippet\">
        </head></html>
        """
        let directives = HTMLParsing.extractMetaDirectives(html: html)
        XCTAssertTrue(directives.contains("noindex"))
        XCTAssertTrue(directives.contains("nofollow"))
        XCTAssertTrue(directives.contains("nosnippet"))
    }

    func testCanonicalDetection() {
        let html = """
        <link rel=\"canonical\" href=\"https://example.com/\" />
        """
        XCTAssertEqual(HTMLParsing.extractCanonical(html: html), "https://example.com/")
    }

    func testJSONLDCount() {
        let html = """
        <script type=\"application/ld+json\"></script>
        <script type=\"application/ld+json\"></script>
        """
        XCTAssertEqual(HTMLParsing.countJSONLDScripts(html: html), 2)
    }

    func testContentSignals() {
        let html = """
        <html><body><main><h1>Hello</h1><article>Content</article></main><script></script></body></html>
        """
        let signals = HTMLParsing.detectContentSignals(html: html)
        XCTAssertTrue(signals.mainPresent)
        XCTAssertTrue(signals.articlePresent)
        XCTAssertTrue(signals.h1Present)
        XCTAssertEqual(signals.scriptCount, 1)
        XCTAssertGreaterThan(signals.textLength, 0)
    }
}
