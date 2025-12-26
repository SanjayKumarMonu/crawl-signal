// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CrawlSignal",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "CrawlSignal",
            targets: ["CrawlSignal"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "CrawlSignal",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk")
            ]
        ),
        .testTarget(
            name: "CrawlSignalTests",
            dependencies: ["CrawlSignal"]
        )
    ]
)
