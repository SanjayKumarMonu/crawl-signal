// File: Sources/CrawlSignal/Logging/Logger.swift
import Foundation

public actor Logger {
    public static let shared = Logger()
    private let fileURL: URL
    private let dateFormatter: DateFormatter

    public nonisolated var logFilePath: String { fileURL.path }

    public init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        self.fileURL = home.appendingPathComponent("crawlsignal.log")
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    }

    public func log(level: String, _ message: String) {
        let timestamp = dateFormatter.string(from: Date())
        let line = "[\(timestamp)] [\(level.uppercased())] \(message)\n"
        write(line)
    }

    private func write(_ text: String) {
        do {
            let data = Data(text.utf8)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                if let handle = try? FileHandle(forWritingTo: fileURL) {
                    try handle.seekToEnd()
                    try handle.write(contentsOf: data)
                    try handle.close()
                }
            } else {
                try data.write(to: fileURL)
            }
        } catch {
            let stderrData = Data("Logger error: \(error)\n".utf8)
            FileHandle.standardError.write(stderrData)
        }
    }
}
