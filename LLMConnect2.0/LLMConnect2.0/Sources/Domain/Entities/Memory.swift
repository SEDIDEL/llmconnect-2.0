//
//  Memory.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import Foundation
import SwiftData

@Model
final class Memory: @unchecked Sendable {
    var id: UUID
    var title: String
    var content: String
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), title: String, content: String, tags: [String] = []) {
        self.id = id
        self.title = title
        self.content = content
        self.tags = tags
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}