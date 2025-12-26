// File: Sources/CrawlSignal/EntryPoint.swift
import Foundation
import MCP

@main
struct CrawlSignalMain {
    static func main() async throws {
        let logger = Logger.shared
        await logger.log(level: "info", "Starting Crawl Signal server")

        let transport = StdioTransport()
        let server = Server(name: "Crawl Signal", version: "0.1.0")

        let robotsService = RobotsTxtService(logger: logger)
        let auditorService = AuditorService(logger: logger, robotsService: robotsService)
        let indexNowService = IndexNowService(logger: logger)
        let perplexityService = PerplexityService(logger: logger)

        // Setup dashboard (unchanged)
        let dashboardTools = [
            DashboardTool(
                title: "Submit to IndexNow",
                description: "Instantly nudge Bing and participating engines with fresh URLs. Retries automatically on rate limits.",
                callToAction: "Use tool: submit_url_indexnow",
                accent: "#60a5fa"
            ),
            DashboardTool(
                title: "Verify Perplexity reach",
                description: "Request a live summary from Perplexity to confirm accessibility, robots friendliness, and paywall signals.",
                callToAction: "Use tool: check_perplexity_status",
                accent: "#f472b6"
            ),
            DashboardTool(
                title: "Audit GEO visibility",
                description: "Analyze meta robots, X-Robots-Tag, canonical signals, JSON-LD, and AI crawler access in one report.",
                callToAction: "Use tool: audit_page_for_geo",
                accent: "#34d399"
            )
        ]

        let dashboardStatus = DashboardStatus(
            indexNowKeyPresent: (ProcessInfo.processInfo.environment["INDEXNOW_KEY"]?.isEmpty == false),
            perplexityKeyPresent: (ProcessInfo.processInfo.environment["PERPLEXITY_API_KEY"]?.isEmpty == false),
            logPath: logger.logFilePath,
            dashboardPath: UIBuilder.defaultDashboardURL().path
        )

        do {
            try UIBuilder.writeDashboard(to: UIBuilder.defaultDashboardURL(), tools: dashboardTools, status: dashboardStatus)
        } catch {
            await logger.log(level: "error", "Failed to write dashboard: \(error)")
        }

        let tools: [Tool] = [
            Tool(
                name: "submit_url_indexnow",
                description: "Submit one or more URLs to IndexNow to encourage indexing.",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "urls": .object([
                            "type": .string("array"),
                            "items": .object(["type": .string("string")]),
                            "description": .string("Array of URLs to submit")
                        ]),
                        "host": .object([
                            "type": .string("string"),
                            "description": .string("Host for IndexNow payload; derived from first URL if omitted")
                        ]),
                        "apiKey": .object([
                            "type": .string("string"),
                            "description": .string("IndexNow API key (falls back to INDEXNOW_KEY env var)")
                        ]),
                        "keyLocation": .object([
                            "type": .string("string"),
                            "description": .string("Location of IndexNow key file; defaults to https://{host}/{apiKey}.txt")
                        ])
                    ]),
                    "required": .array([.string("urls")])
                ])
            ),
            Tool(
                name: "check_perplexity_status",
                description: "Verify Perplexity visibility by requesting a URL summary.",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "url": .object([
                            "type": .string("string"),
                            "description": .string("URL to check")
                        ]),
                        "apiKey": .object([
                            "type": .string("string"),
                            "description": .string("Perplexity API key (falls back to PERPLEXITY_API_KEY env var)")
                        ]),
                        "model": .object([
                            "type": .string("string"),
                            "description": .string("Perplexity model to use (default sonar-pro)")
                        ])
                    ]),
                    "required": .array([.string("url")])
                ])
            ),
            Tool(
                name: "audit_page_for_geo",
                description: "Audit a page for GEO / AI crawler visibility signals.",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "url": .object([
                            "type": .string("string"),
                            "description": .string("URL to audit")
                        ]),
                        "checkRobotsTxt": .object([
                            "type": .string("boolean"),
                            "description": .string("Whether to fetch and inspect robots.txt (default true)")
                        ])
                    ]),
                    "required": .array([.string("url")])
                ])
            )
        ]

        // FIXED: Use withMethodHandler for ListTools
        await server.withMethodHandler(ListTools.self) { _ in
            return ListTools.Result(tools: tools)
        }

        // FIXED: Use withMethodHandler for CallTool
        await server.withMethodHandler(CallTool.self) { request in
            // request.arguments is [String: Value]?, so we rely on ValueHelpers.swift to extract data
            let args = request.arguments ?? [:]
            
            switch request.name {
            case "submit_url_indexnow":
                // Extract using helper properties from ValueHelpers.swift
                let urlValues: [String] = args["urls"]?.arrayValue?.compactMap { $0.stringValue } ?? []
                // Fallback for single string input if array extraction failed but string exists
                if urlValues.isEmpty, let single = args["urls"]?.stringValue {
                     // logic to handle single string if necessary, though schema defines array
                }
                
                let host = args["host"]?.stringValue
                let apiKey = args["apiKey"]?.stringValue
                let keyLocation = args["keyLocation"]?.stringValue
                
                do {
                    // Ensure urlValues is not empty if required
                    let urlsToSubmit = urlValues.isEmpty && args["urls"]?.stringValue != nil ? [args["urls"]!.stringValue!] : urlValues
                    
                    let result = try await indexNowService.submit(urlStrings: urlsToSubmit, host: host, apiKey: apiKey, keyLocation: keyLocation)
                    return CallTool.Result(content: [.text(result)], isError: false)
                } catch {
                    await logger.log(level: "error", "IndexNow tool error: \(error)")
                    return CallTool.Result(content: [.text(error.localizedDescription)], isError: true)
                }

            case "check_perplexity_status":
                let url = args["url"]?.stringValue ?? ""
                let apiKey = args["apiKey"]?.stringValue
                let model = args["model"]?.stringValue
                
                do {
                    let summary = try await perplexityService.check(urlString: url, apiKey: apiKey, model: model)
                    return CallTool.Result(content: [.text(summary)], isError: false)
                } catch {
                    await logger.log(level: "error", "Perplexity tool error: \(error)")
                    return CallTool.Result(content: [.text(error.localizedDescription)], isError: true)
                }

            case "audit_page_for_geo":
                let url = args["url"]?.stringValue ?? ""
                let check = args["checkRobotsTxt"]?.boolValue ?? true
                let report = await auditorService.audit(urlString: url, checkRobotsTxt: check)
                return CallTool.Result(content: [.text(report)], isError: false)

            default:
                return CallTool.Result(content: [.text("Unknown tool: \(request.name)")], isError: true)
            }
        }

        try await server.start(transport: transport)
    }
}
