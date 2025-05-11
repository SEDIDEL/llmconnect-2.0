//
//  GenerateImageUseCase.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import Foundation

class GenerateImageUseCase {
    private let imageRepository: ImageGenerationRepositoryProtocol
    
    init(imageRepository: ImageGenerationRepositoryProtocol) {
        self.imageRepository = imageRepository
    }
    
    func execute(prompt: String, model: String, width: Int, height: Int) async throws -> GeneratedImage {
        return try await imageRepository.generateImage(prompt: prompt, model: model, width: width, height: height)
    }
}