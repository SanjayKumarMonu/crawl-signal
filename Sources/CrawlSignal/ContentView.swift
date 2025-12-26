import SwiftUI

struct ContentView: View {
    // We use a sidebar navigation style
    @State private var selectedTab: Tab? = .audit
    
    enum Tab {
        case audit, indexnow, perplexity
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                Label("Audit & SEO", systemImage: "checkmark.shield")
                    .tag(Tab.audit)
                Label("IndexNow", systemImage: "paperplane")
                    .tag(Tab.indexnow)
                Label("Perplexity Check", systemImage: "magnifyingglass")
                    .tag(Tab.perplexity)
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 220)
            .listStyle(SidebarListStyle())
        } detail: {
            switch selectedTab {
            case .audit: AuditView()
            case .indexnow: IndexNowView()
            case .perplexity: PerplexityView()
            case .none: Text("Select a tool")
            }
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}

// MARK: - 1. Audit View
struct AuditView: View {
    @State private var urlString = "https://"
    @State private var report = ""
    @State private var isAnalyzing = false
    
    // FIX: Add Focus State to control keyboard focus
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HeaderView(title: "Page Audit", subtitle: "Analyze if AI bots can read your content.")
            
            HStack {
                // FIX: Use standard .roundedBorder for maximum compatibility
                TextField("Website URL", text: $urlString)
                    .textFieldStyle(.roundedBorder)
                    .focused($isTextFieldFocused) // Bind focus here
                    .onSubmit { runAudit() }      // Allow pressing Enter to submit
                
                Button("Run Audit") {
                    runAudit()
                }
                .buttonStyle(.borderedProminent)
                .disabled(urlString.isEmpty || isAnalyzing)
            }
            .padding(.horizontal)
            
            if isAnalyzing {
                HStack {
                    ProgressView().scaleEffect(0.5)
                    Text("Fetching page and checking robots.txt...")
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }
            
            TextEditor(text: .constant(report))
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(8)
                .padding()
        }
        // FIX: Force focus when the view appears (with a slight delay to override sidebar)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isTextFieldFocused = true
            }
        }
    }
    
    func runAudit() {
        guard !urlString.isEmpty else { return }
        isAnalyzing = true
        report = ""
        
        Task {
            let logger = Logger.shared
            let robotsService = RobotsTxtService(logger: logger)
            let auditor = AuditorService(logger: logger, robotsService: robotsService)
            
            let result = await auditor.audit(urlString: urlString, checkRobotsTxt: true)
            
            DispatchQueue.main.async {
                self.report = result
                self.isAnalyzing = false
                self.isTextFieldFocused = true // Refocus after running
            }
        }
    }
}

// MARK: - 2. IndexNow View
struct IndexNowView: View {
    @AppStorage("IndexNowKey") private var apiKey = ""
    @State private var urlsText = ""
    @State private var host = ""
    @State private var log = ""
    @State private var isSubmitting = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HeaderView(title: "IndexNow Submitter", subtitle: "Instantly notify Bing & Yandex about content changes.")
            
            Form {
                Section("Configuration") {
                    TextField("API Key", text: $apiKey)
                    TextField("Host (e.g. example.com)", text: $host)
                }
                
                Section("URLs (One per line)") {
                    TextEditor(text: $urlsText)
                        .frame(height: 100)
                        .font(.body)
                }
            }
            .formStyle(.grouped)
            .padding(.horizontal)
            
            HStack {
                Button("Submit URLs") {
                    submit()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSubmitting || apiKey.isEmpty || urlsText.isEmpty)
                
                if isSubmitting { ProgressView().scaleEffect(0.8) }
            }
            .padding(.horizontal)
            
            if !log.isEmpty {
                Text(log)
                    .foregroundStyle(.secondary)
                    .padding()
            }
            
            Spacer()
        }
    }
    
    func submit() {
        let urls = urlsText.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard !urls.isEmpty else { return }
        
        isSubmitting = true
        log = "Submitting..."
        
        Task {
            let service = IndexNowService(logger: Logger.shared)
            do {
                let result = try await service.submit(
                    urlStrings: urls,
                    host: host.isEmpty ? nil : host,
                    apiKey: apiKey,
                    keyLocation: nil
                )
                DispatchQueue.main.async {
                    self.log = "Success: \(result)"
                    self.isSubmitting = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.log = "Error: \(error.localizedDescription)"
                    self.isSubmitting = false
                }
            }
        }
    }
}

// MARK: - 3. Perplexity View
struct PerplexityView: View {
    @AppStorage("PerplexityKey") private var apiKey = ""
    @State private var urlString = ""
    @State private var output = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HeaderView(title: "Perplexity Check", subtitle: "See how Perplexity's 'sonar' model views your page.")
            
            VStack(alignment: .leading) {
                Text("API Key")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                SecureField("pplx-...", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.horizontal)
            
            HStack {
                TextField("URL to check", text: $urlString)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { check() }
                
                Button("Check Reachability") {
                    check()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || apiKey.isEmpty)
            }
            .padding(.horizontal)
            
            if isLoading {
                ProgressView("Asking Perplexity...")
                    .padding()
            }
            
            ScrollView {
                Text(output)
                    .padding()
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .textBackgroundColor))
            .cornerRadius(8)
            .padding()
        }
    }
    
    func check() {
        guard !urlString.isEmpty else { return }
        isLoading = true
        output = ""
        
        Task {
            let service = PerplexityService(logger: Logger.shared)
            do {
                let result = try await service.check(urlString: urlString, apiKey: apiKey, model: "sonar-pro")
                DispatchQueue.main.async {
                    self.output = result
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.output = "Error: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}

// Helper for consistency
struct HeaderView: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.largeTitle).bold()
            Text(subtitle).font(.title3).foregroundStyle(.secondary)
            Divider()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
