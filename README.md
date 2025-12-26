# Crawl Signal

Crawl Signal is a native macOS SwiftUI app that surfaces SEO and AI-indexing workflows in a single desktop dashboard. It reuses the core services for IndexNow submission, Perplexity visibility checks, and page audits for AI crawler readiness.

## Prerequisites
- macOS 13+ (tested with Swift 6 / Xcode 16 toolchain)
- Swift Package Manager
- Network access to IndexNow and Perplexity APIs

## Running the app
Open the package in Xcode and run the `CrawlSignal` scheme. The SwiftUI dashboard provides three tools:
- **Audit & SEO** — analyze a URL for robots directives, canonical tags, JSON-LD, and content signals.
- **IndexNow Submitter** — push URLs to IndexNow; keys are saved with `@AppStorage`.
- **Perplexity Check** — confirm Perplexity can reach and summarize a URL.

API keys persist locally through `@AppStorage` (`indexNowKey`, `perplexityKey`). Logs continue to write to `~/crawlsignal.log`.

## Building from the command line
```bash
swift build
```

The build products live under `.build/` (for SPM) or `.swiftpm/xcode/Products/` (from Xcode).

## Security notes
- Keep API keys secret. Avoid embedding keys in source control.
- Logs do not include secrets intentionally, but they reside in `~/crawlsignal.log`. Protect file permissions accordingly.

## Troubleshooting
- Ensure outbound network access to the IndexNow and Perplexity endpoints.
- If the IndexNow endpoint returns 429, the service backs off up to four times; repeated 429s surface as an error.
- Non-HTML responses during audit are reported as warnings.
- Perplexity HTTP errors return a response snippet for debugging.
