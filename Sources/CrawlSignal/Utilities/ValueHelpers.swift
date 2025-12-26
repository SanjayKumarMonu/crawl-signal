// File: Sources/CrawlSignalCore/Utilities/ValueHelpers.swift
import MCP

extension Value {
    var stringValue: String? {
        switch self {
        case .string(let value):
            return value
        default:
            return nil
        }
    }

    var arrayValue: [Value]? {
        switch self {
        case .array(let values):
            return values
        default:
            return nil
        }
    }

    var boolValue: Bool? {
        switch self {
        case .boolean(let value):
            return value
        default:
            return nil
        }
    }
}
