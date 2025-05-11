//
//  Chat.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import Foundation
import SwiftData

@Model
final class Chat: @unchecked Sendable {
    var id: UUID
    var title: String?
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool
    var isArchived: Bool
    var providerIdentifier: String
    var modelIdentifier: String

    // Corregimos la relación para evitar el uso de .cascade que no existe
    @Relationship(deleteRule: .cascade)
    var messages: [Message]

    @Relationship
    var folders: [Folder]?

    init(
        id: UUID = UUID(),
        title: String? = nil,
        providerIdentifier: String,
        modelIdentifier: String,
        isPinned: Bool = false,
        isArchived: Bool = false
    ) {
        self.id = id
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isPinned = isPinned
        self.isArchived = isArchived
        self.providerIdentifier = providerIdentifier
        self.modelIdentifier = modelIdentifier
        self.messages = []
    }
}

@Model
final class Folder {
    var id: UUID
    var name: String
    var color: String
    var createdAt: Date

    @Relationship
    var chats: [Chat]?

    init(id: UUID = UUID(), name: String, color: String) {
        self.id = id
        self.name = name
        self.color = color
        self.createdAt = Date()
    }
}

// Mark Folder as Sendable for concurrency safety
extension Folder: @unchecked Sendable {}