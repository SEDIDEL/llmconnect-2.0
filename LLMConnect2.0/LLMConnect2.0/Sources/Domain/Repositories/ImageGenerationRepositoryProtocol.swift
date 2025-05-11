//
//  ImageGenerationRepositoryProtocol.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import Foundation

protocol ImageGenerationRepositoryProtocol {
    func generateImage(prompt: String, model: String, width: Int, height: Int) async throws -> GeneratedImage
    func getGeneratedImages() async throws -> [GeneratedImage]
    func deleteGeneratedImage(id: UUID) async throws
    func getAvailableImageModels() async throws -> [ImageModel]
}

struct ImageModel: Sendable {
    let id: String
    let name: String
    let provider: String
    let description: String
    let minWidth: Int
    let maxWidth: Int
    let minHeight: Int
    let maxHeight: Int
    let supportedStyles: [String]
}