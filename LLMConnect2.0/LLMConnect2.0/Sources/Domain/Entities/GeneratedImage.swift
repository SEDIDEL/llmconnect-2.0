//
//  GeneratedImage.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import Foundation
import SwiftData

@Model
final class GeneratedImage: @unchecked Sendable {
    var id: UUID
    var prompt: String
    var imageURL: URL
    var thumbnailURL: URL
    var model: String
    var createdAt: Date
    var width: Int
    var height: Int
    
    init(
        id: UUID = UUID(),
        prompt: String,
        imageURL: URL,
        thumbnailURL: URL,
        model: String,
        width: Int,
        height: Int
    ) {
        self.id = id
        self.prompt = prompt
        self.imageURL = imageURL
        self.thumbnailURL = thumbnailURL
        self.model = model
        self.createdAt = Date()
        self.width = width
        self.height = height
    }
}