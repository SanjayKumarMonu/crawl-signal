// File: Tests/CrawlSignalTests/UIBuilderTests.swift
import XCTest
@testable import CrawlSignal

final class UIBuilderTests: XCTestCase {
    func testDashboardHTMLContainsSections() {
        let tools = [
            DashboardTool(title: "Tool A", description: "Desc", callToAction: "Do it", accent: "#fff")
        ]
        let status = DashboardStatus(indexNowKeyPresent: true, perplexityKeyPresent: false, logPath: "/tmp/log", dashboardPath: "/tmp/dash")
        let html = UIBuilder.dashboardHTML(tools: tools, status: status)
        XCTAssertTrue(html.contains("Crawl Signal"))
        XCTAssertTrue(html.contains("Tool A"))
        XCTAssertTrue(html.contains("IndexNow key"))
        XCTAssertTrue(html.contains("Perplexity key"))
    }
}
