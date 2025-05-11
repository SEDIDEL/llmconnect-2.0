//
//  Prompt.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import Foundation
import SwiftData

@Model
final class Prompt: @unchecked Sendable {
    var id: UUID
    var title: String
    var content: String
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship
    var category: PromptCategory?
    
    init(id: UUID = UUID(), title: String, content: String, tags: [String] = []) {
        self.id = id
        self.title = title
        self.content = content
        self.tags = tags
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

@Model
final class PromptCategory: @unchecked Sendable {
    var id: UUID
    var name: String
    var color: String
    
    @Relationship(deleteRule: .cascade)
    var prompts: [Prompt]?
    
    init(id: UUID = UUID(), name: String, color: String) {
        self.id = id
        self.name = name
        self.color = color
    }
}