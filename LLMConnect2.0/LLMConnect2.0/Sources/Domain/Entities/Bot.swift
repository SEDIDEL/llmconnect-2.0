//
//  Bot.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import Foundation
import SwiftData

@Model
final class Bot: @unchecked Sendable {
    var id: UUID
    var name: String
    var emoji: String
    var botDescription: String // Cambiado de "description" a "botDescription" para evitar conflicto
    var systemPrompt: String
    var providerIdentifier: String
    var modelIdentifier: String
    var isEditable: Bool
    var createdAt: Date
    var updatedAt: Date

    // Corregimos la relación para evitar el uso de .cascade que no existe
    @Relationship(deleteRule: .cascade)
    var knowledgeSources: [KnowledgeSource]?

    init(
        id: UUID = UUID(),
        name: String,
        emoji: String,
        botDescription: String,
        systemPrompt: String,
        providerIdentifier: String,
        modelIdentifier: String,
        isEditable: Bool = true
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.botDescription = botDescription
        self.systemPrompt = systemPrompt
        self.providerIdentifier = providerIdentifier
        self.modelIdentifier = modelIdentifier
        self.isEditable = isEditable
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

@Model
final class KnowledgeSource: @unchecked Sendable {
    var id: UUID
    var name: String
    var content: String
    var createdAt: Date

    init(id: UUID = UUID(), name: String, content: String) {
        self.id = id
        self.name = name
        self.content = content
        self.createdAt = Date()
    }
}