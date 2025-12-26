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
    ],
    targets: [
        .executableTarget(
            name: "CrawlSignal",
            dependencies: [
            ]
        ),
        .testTarget(
            name: "CrawlSignalTests",
            dependencies: ["CrawlSignal"]
        )
    ]
)
