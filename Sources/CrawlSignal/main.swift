// File: Sources/CrawlSignal/main.swift
import Foundation
import MCP

@main
struct CrawlSignalMain {
    static func main() async throws {
        let logger = Logger.shared
        await logger.log(level: "info", "Starting Crawl Signal server")

        let transport = StdioTransport()
        let server = Server(name: "Crawl Signal", version: "0.1.0", transport: transport)

        let robotsService = RobotsTxtService(logger: logger)
        let auditorService = AuditorService(logger: logger, robotsService: robotsService)
        let indexNowService = IndexNowService(logger: logger)
        let perplexityService = PerplexityService(logger: logger)

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

        server.registerListToolsHandler { _ in
            return ListToolsResult(tools: tools)
        }

        server.registerCallToolHandler { params in
            switch params.name {
            case "submit_url_indexnow":
                let args = params.arguments ?? [:]
                let urlValues: [String]
                if let urlsArray = args["urls"]?.arrayValue {
                    urlValues = urlsArray.compactMap { $0.stringValue }
                } else if let single = args["urls"]?.stringValue {
                    urlValues = [single]
                } else {
                    urlValues = []
                }
                let host = args["host"]?.stringValue
                let apiKey = args["apiKey"]?.stringValue
                let keyLocation = args["keyLocation"]?.stringValue
                do {
                    let result = try await indexNowService.submit(urlStrings: urlValues, host: host, apiKey: apiKey, keyLocation: keyLocation)
                    return CallTool.Result(content: [.text(result)], isError: false)
                } catch {
                    await logger.log(level: "error", "IndexNow tool error: \(error)")
                    return CallTool.Result(content: [.text(error.localizedDescription)], isError: true)
                }

            case "check_perplexity_status":
                let args = params.arguments ?? [:]
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
                let args = params.arguments ?? [:]
                let url = args["url"]?.stringValue ?? ""
                let check = args["checkRobotsTxt"]?.boolValue ?? true
                let report = await auditorService.audit(urlString: url, checkRobotsTxt: check)
                return CallTool.Result(content: [.text(report)], isError: false)

            default:
                return CallTool.Result(content: [.text("Unknown tool: \(params.name)")], isError: true)
            }
        }

        try await server.start()
    }
}
