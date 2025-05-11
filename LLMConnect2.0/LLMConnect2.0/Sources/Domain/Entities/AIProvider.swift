//
//  AIProvider.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import Foundation

enum AIProvider: String, CaseIterable, Identifiable {
    case openAI = "OpenAI"
    case anthropic = "Anthropic"
    case groq = "Groq"
    case perplexity = "Perplexity"
    case deepSeek = "DeepSeek"
    case openRouter = "OpenRouter"
    case custom = "Custom"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
    
    var iconName: String {
        switch self {
        case .openAI:
            return "openai-icon"
        case .anthropic:
            return "anthropic-icon"
        case .groq:
            return "groq-icon"
        case .perplexity:
            return "perplexity-icon"
        case .deepSeek:
            return "deepseek-icon"
        case .openRouter:
            return "openrouter-icon"
        case .custom:
            return "custom-icon"
        }
    }
    
    var baseURL: URL {
        switch self {
        case .openAI:
            return URL(string: "https://api.openai.com/v1")!
        case .anthropic:
            return URL(string: "https://api.anthropic.com/v1")!
        case .groq:
            return URL(string: "https://api.groq.com/v1")!
        case .perplexity:
            return URL(string: "https://api.perplexity.ai")!
        case .deepSeek:
            return URL(string: "https://api.deepseek.com/v1")!
        case .openRouter:
            return URL(string: "https://openrouter.ai/api/v1")!
        case .custom:
            // Custom providers will have their URLs stored in the database
            return URL(string: "https://custom.api.example.com")!
        }
    }
}