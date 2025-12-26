// File: Sources/CrawlSignal/Utilities/UIBuilder.swift
import Foundation

struct DashboardTool {
    let title: String
    let description: String
    let callToAction: String
    let accent: String
}

struct DashboardStatus {
    let indexNowKeyPresent: Bool
    let perplexityKeyPresent: Bool
    let logPath: String
    let dashboardPath: String
}

enum UIBuilder {
    static func dashboardHTML(tools: [DashboardTool], status: DashboardStatus) -> String {
        let toolCards = tools.map { tool in
            """
            <div class=\"card\" style=\"border-top: 4px solid \(tool.accent);\">
                <div class=\"card-title\">\(tool.title)</div>
                <div class=\"card-body\">\(tool.description)</div>
                <div class=\"cta\">\(tool.callToAction)</div>
            </div>
            """
        }.joined(separator: "\n")

        let statusTags = """
        <div class=\"status-grid\">
            <div class=\"pill \(status.indexNowKeyPresent ? "pill-on" : "pill-off")\">IndexNow key \(status.indexNowKeyPresent ? "set" : "missing")</div>
            <div class=\"pill \(status.perplexityKeyPresent ? "pill-on" : "pill-off")\">Perplexity key \(status.perplexityKeyPresent ? "set" : "missing")</div>
            <div class=\"pill pill-neutral\">Log file: \(status.logPath)</div>
            <div class=\"pill pill-neutral\">Dashboard: \(status.dashboardPath)</div>
        </div>
        """

        return """
        <!doctype html>
        <html lang=\"en\">
        <head>
            <meta charset=\"utf-8\">
            <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
            <title>Crawl Signal</title>
            <style>
                :root { color-scheme: light dark; }
                body { margin: 0; font-family: -apple-system, SF Pro Display, Arial, sans-serif; background: radial-gradient(circle at 20% 20%, #1b2030, #0c0f1a); color: #e8ecf5; }
                .shell { max-width: 1100px; margin: 0 auto; padding: 48px 28px 64px; }
                .hero { display: grid; gap: 12px; }
                .title { font-size: 40px; font-weight: 700; letter-spacing: -0.6px; }
                .subtitle { font-size: 17px; color: #cbd5e1; max-width: 780px; line-height: 1.5; }
                .panel { background: linear-gradient(135deg, rgba(255,255,255,0.06), rgba(255,255,255,0.02)); border: 1px solid rgba(255,255,255,0.08); border-radius: 18px; padding: 24px; box-shadow: 0 12px 40px rgba(0,0,0,0.35); }
                .cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 16px; margin-top: 16px; }
                .card { background: rgba(255,255,255,0.04); border-radius: 16px; padding: 18px; border: 1px solid rgba(255,255,255,0.06); box-shadow: 0 10px 30px rgba(0,0,0,0.25); }
                .card-title { font-size: 20px; font-weight: 600; margin-bottom: 8px; }
                .card-body { font-size: 15px; color: #cdd6e4; line-height: 1.5; }
                .cta { margin-top: 12px; font-weight: 600; color: #b5c7ff; }
                .status-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 10px; margin-top: 16px; }
                .pill { padding: 10px 12px; border-radius: 12px; font-size: 14px; text-align: center; font-weight: 600; border: 1px solid rgba(255,255,255,0.12); }
                .pill-on { background: rgba(34,197,94,0.12); color: #98f3c5; border-color: rgba(34,197,94,0.35); }
                .pill-off { background: rgba(239,68,68,0.12); color: #ffc0c0; border-color: rgba(239,68,68,0.25); }
                .pill-neutral { background: rgba(255,255,255,0.06); color: #dce6ff; }
                .section-title { font-size: 16px; letter-spacing: 0.6px; text-transform: uppercase; color: #8aa0ff; font-weight: 700; margin-top: 4px; }
            </style>
        </head>
        <body>
            <div class=\"shell\">
                <div class=\"hero\">
                    <div class=\"section-title\">Crawl Signal</div>
                    <div class=\"title\">Precision signals for AI discovery</div>
                    <div class=\"subtitle\">A native MCP server that fast-tracks indexing, validates Perplexity access, and spotlights GEO readiness. Crafted for clarity and a calm, confident flow.</div>
                    <div class=\"panel\">
                        <div class=\"section-title\">Environment health</div>
                        \(statusTags)
                    </div>
                </div>
                <div class=\"panel\" style=\"margin-top: 22px;\">
                    <div class=\"section-title\">MCP tools</div>
                    <div class=\"cards\">
                        \(toolCards)
                    </div>
                </div>
            </div>
        </body>
        </html>
        """
    }

    static func writeDashboard(to url: URL, tools: [DashboardTool], status: DashboardStatus) throws {
        let html = dashboardHTML(tools: tools, status: status)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try html.data(using: .utf8)?.write(to: url)
    }

    static func defaultDashboardURL() -> URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent("crawlsignal_dashboard.html")
    }
}
