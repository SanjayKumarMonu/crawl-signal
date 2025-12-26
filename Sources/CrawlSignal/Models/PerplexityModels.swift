// File: Sources/CrawlSignal/Models/PerplexityModels.swift
import Foundation

struct PerplexityMessage: Codable, Equatable {
    let role: String
    let content: String
}

struct PerplexityRequest: Codable, Equatable {
    let model: String
    let messages: [PerplexityMessage]
}

struct PerplexityChoiceMessage: Codable {
    let role: String
    let content: String
}

struct PerplexityChoice: Codable {
    let index: Int
    let message: PerplexityChoiceMessage
}

struct PerplexityResponse: Codable {
    let choices: [PerplexityChoice]
}
