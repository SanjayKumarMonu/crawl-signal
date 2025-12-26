# Crawl Signal

Crawl Signal is a native macOS MCP server (stdio transport) that helps with AI indexing and GEO visibility workflows. It exposes tools for IndexNow submission, Perplexity visibility checks, and page audits for AI crawler readiness. The executable binary is `CrawlSignal`.

## Prerequisites
- macOS 13+ (tested with Swift 6 / Xcode 16 toolchain)
- Swift Package Manager
- Network access to IndexNow and Perplexity APIs

## Building
```bash
swift build -c release
```

After building, the binary will be located at:
```
.swiftpm/xcode/Products/Release/CrawlSignal (Xcode) or .build/release/CrawlSignal (SPM CLI)
```

## Installation
You can run directly from the build output or copy the binary somewhere on your PATH, e.g.:
```bash
cp .build/release/CrawlSignal /usr/local/bin/
```

## Claude Desktop configuration example
Create or extend your `claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "crawl-signal": {
      "command": "/ABS/PATH/TO/BINARY/CrawlSignal",
      "args": [],
      "env": {
        "INDEXNOW_KEY": "YOUR_KEY",
        "PERPLEXITY_API_KEY": "YOUR_KEY",
        "PERPLEXITY_MODEL": "sonar-pro"
      }
    }
  }
}
```

## Usage notes
- The server communicates over stdio; do not send other output to stdout. Logs are written to `~/crawlsignal.log` and stderr for logger failures.
- API keys can be supplied as tool arguments but environment variables are preferred: `INDEXNOW_KEY`, `INDEXNOW_KEY_LOCATION`, `PERPLEXITY_API_KEY`, `PERPLEXITY_MODEL`.
- IndexNow submissions POST to `https://api.indexnow.org/indexnow` and automatically retry on HTTP 429 with exponential backoff.
- Perplexity checks call `https://api.perplexity.ai/chat/completions` with a diagnostic prompt to force URL access.
- Audits fetch the page, analyze meta robots, X-Robots-Tag, canonical, JSON-LD presence, content signals, and optionally evaluate `robots.txt` for common AI bots.
- On startup the server writes a curated HTML dashboard to `~/crawlsignal_dashboard.html` highlighting tool purpose, environment health, and file locations.

## Security notes
- Keep API keys secret. Avoid embedding keys in source control; prefer environment variables.
- Logs do not include secrets intentionally, but they reside in `~/crawlsignal.log`. Protect file permissions accordingly.

## Troubleshooting
- Ensure the binary has execute permissions.
- If tools fail with missing keys, set the required env vars in the Claude Desktop configuration.
- If the IndexNow endpoint returns 429, the tool backs off up to 4 times; repeated 429s will surface as an error.
- Non-HTML responses during audit will be reported as warnings.
- Perplexity HTTP errors will return the response snippet for debugging.

## Testing
Run the unit test suite:
```bash
swift test
```
