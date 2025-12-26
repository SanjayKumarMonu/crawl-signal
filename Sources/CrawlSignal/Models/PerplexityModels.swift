// File: Sources/CrawlSignal/Models/PerplexityModels.swift
import Foundation

public struct PerplexityMessage: Codable, Equatable {
    public let role: String
    public let content: String

    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

public struct PerplexityRequest: Codable, Equatable {
    public let model: String
    public let messages: [PerplexityMessage]

    public init(model: String, messages: [PerplexityMessage]) {
        self.model = model
        self.messages = messages
    }
}

public struct PerplexityChoiceMessage: Codable {
    public let role: String
    public let content: String
}

public struct PerplexityChoice: Codable {
    public let index: Int
    public let message: PerplexityChoiceMessage
}

public struct PerplexityResponse: Codable {
    public let choices: [PerplexityChoice]
}
