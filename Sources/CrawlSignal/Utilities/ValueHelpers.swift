// File: Sources/CrawlSignal/Utilities/ValueHelpers.swift
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
        // FIXED: Changed .boolean to .bool
        case .bool(let value):
            return value
        default:
            return nil
        }
    }
}
