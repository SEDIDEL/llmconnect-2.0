//
//  Message.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import Foundation
import SwiftData

@Model
final class Message: @unchecked Sendable {
    var id: UUID
    var role: Role
    var content: String
    var timestamp: Date

    // Corregimos la relación para evitar el uso de .cascade que no existe
    @Relationship(deleteRule: .cascade)
    var citations: [Citation]?

    enum Role: String, Codable {
        case user
        case assistant
        case system
    }

    init(id: UUID = UUID(), role: Role, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

@Model
final class Citation: @unchecked Sendable {
    var id: UUID
    var text: String
    var startIndex: Int
    var endIndex: Int
    var sourceType: SourceType
    var sourceIdentifier: String

    enum SourceType: String, Codable {
        case memory
        case knowledgeSource
        case web
        case document
    }

    init(
        id: UUID = UUID(),
        text: String,
        startIndex: Int,
        endIndex: Int,
        sourceType: SourceType,
        sourceIdentifier: String
    ) {
        self.id = id
        self.text = text
        self.startIndex = startIndex
        self.endIndex = endIndex
        self.sourceType = sourceType
        self.sourceIdentifier = sourceIdentifier
    }
}