import SwiftUI

struct ContentView: View {
    @State private var selectedTab: String? = "audit"

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                Label("Audit & SEO", systemImage: "checkmark.shield").tag("audit")
                Label("IndexNow Submitter", systemImage: "paperplane").tag("indexnow")
                Label("Perplexity Check", systemImage: "magnifyingglass").tag("perplexity")
            }
            .listStyle(SidebarListStyle())
            .navigationTitle("Crawl Signal")
        } detail: {
            if let tab = selectedTab {
                switch tab {
                case "audit": AuditView()
                case "indexnow": IndexNowView()
                case "perplexity": PerplexityView()
                default: Text("Select a tool")
                }
            }
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}

// MARK: - Audit View
struct AuditView: View {
    @State private var urlString = "https://"
    @State private var report = ""
    @State private var isAnalyzing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Readiness Audit").font(.headline)
            HStack {
                TextField("Website URL", text: $urlString).textFieldStyle(.roundedBorder)
                Button("Analyze") {
                    runAudit()
                }
                .disabled(isAnalyzing)
            }
            if isAnalyzing { ProgressView() }
            TextEditor(text: .constant(report))
                .font(.system(.body, design: .monospaced))
                .border(Color.gray.opacity(0.2))
        }
        .padding()
    }

    func runAudit() {
        isAnalyzing = true
        Task {
            let logger = Logger.shared
            let robots = RobotsTxtService(logger: logger)
            let auditor = AuditorService(logger: logger, robotsService: robots)
            let result = await auditor.audit(urlString: urlString, checkRobotsTxt: true)
            DispatchQueue.main.async {
                self.report = result
                self.isAnalyzing = false
            }
        }
    }
}

// MARK: - IndexNow View
struct IndexNowView: View {
    @AppStorage("indexNowKey") private var apiKey = ""
    @State private var urlsText = ""
    @State private var host = ""
    @State private var log = ""
    
    var body: some View {
        Form {
            Section("Settings") {
                TextField("API Key", text: $apiKey)
                TextField("Host (e.g. example.com)", text: $host)
            }
            Section("URLs to Submit") {
                TextEditor(text: $urlsText).frame(height: 100)
                Button("Submit") { submit() }
            }
            if !log.isEmpty { Text(log).foregroundStyle(.secondary) }
        }
        .padding()
    }

    func submit() {
        let urls = urlsText.components(separatedBy: .newlines).filter { !$0.isEmpty }
        Task {
            let service = IndexNowService(logger: Logger.shared)
            do {
                let res = try await service.submit(urlStrings: urls, host: host.isEmpty ? nil : host, apiKey: apiKey, keyLocation: nil)
                DispatchQueue.main.async { log = "Success: \(res)" }
            } catch {
                DispatchQueue.main.async { log = "Error: \(error.localizedDescription)" }
            }
        }
    }
}

// MARK: - Perplexity View
struct PerplexityView: View {
    @AppStorage("perplexityKey") private var apiKey = ""
    @State private var url = ""
    @State private var output = ""
    @State private var loading = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Perplexity Visibility").font(.headline)
            TextField("API Key", text: $apiKey).textFieldStyle(.roundedBorder)
            HStack {
                TextField("URL", text: $url).textFieldStyle(.roundedBorder)
                Button("Check") { check() }.disabled(loading)
            }
            if loading { ProgressView() }
            ScrollView { Text(output).padding() }
        }
        .padding()
    }
    
    func check() {
        loading = true
        Task {
            let service = PerplexityService(logger: Logger.shared)
            do {
                let res = try await service.check(urlString: url, apiKey: apiKey, model: "sonar-pro")
                DispatchQueue.main.async { output = res; loading = false }
            } catch {
                DispatchQueue.main.async { output = "Error: \(error.localizedDescription)"; loading = false }
            }
        }
    }
}
