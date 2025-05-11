//
//  ImageGenerationRepository.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import Foundation
import SwiftData

@MainActor
class ImageGenerationRepository: ImageGenerationRepositoryProtocol {
    private let swiftDataManager: SwiftDataManager
    private let fileManager = FileManager.default

    init() {
        self.swiftDataManager = SwiftDataManager.shared
    }
    
    func generateImage(prompt: String, model: String, width: Int, height: Int) async throws -> GeneratedImage {
        // En una implementación real, esto conectaría con un servicio de IA generativa como Replicate, Dall-E, etc.
        // Por ahora, esto es solo un placeholder

        let modelName = model

        // Simulamos URLs para la imagen generada
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imageName = UUID().uuidString
        let imageURL = documentsDirectory.appendingPathComponent("\(imageName).png")
        let thumbnailURL = documentsDirectory.appendingPathComponent("\(imageName)_thumb.png")

        // Creamos la entidad de imagen generada
        let generatedImage = GeneratedImage(
            prompt: prompt,
            imageURL: imageURL,
            thumbnailURL: thumbnailURL,
            model: modelName,
            width: width,
            height: height
        )

        try await swiftDataManager.save()

        return generatedImage
    }

    func getGeneratedImages() async throws -> [GeneratedImage] {
        return try await swiftDataManager.fetch(
            GeneratedImage.self,
            sortBy: [SortDescriptor(\GeneratedImage.createdAt, order: .reverse)]
        )
    }

    func deleteGeneratedImage(id: UUID) async throws {
        guard let image = try await swiftDataManager.fetchOne(
            GeneratedImage.self,
            predicate: #Predicate<GeneratedImage> { $0.id == id }
        ) else {
            throw DatabaseError.deleteFailed
        }

        // Borramos los archivos de imagen
        try? fileManager.removeItem(at: image.imageURL)
        try? fileManager.removeItem(at: image.thumbnailURL)

        // Borramos la entidad
        try await swiftDataManager.delete(image)
    }
    
    func getAvailableImageModels() async throws -> [ImageModel] {
        // Aquí definimos modelos de imagen que el usuario podría usar
        // En una implementación real, estos podrían venir de un API
        
        let models = [
            ImageModel(
                id: "stability-diffusion-xl",
                name: "Stable Diffusion XL",
                provider: "Stability AI",
                description: "High quality image generation with SDXL",
                minWidth: 512,
                maxWidth: 1024,
                minHeight: 512,
                maxHeight: 1024,
                supportedStyles: ["photorealistic", "artistic", "3d", "cartoon"]
            ),
            ImageModel(
                id: "dall-e-3",
                name: "DALL-E 3",
                provider: "OpenAI",
                description: "Advanced image generation model from OpenAI",
                minWidth: 1024,
                maxWidth: 1792,
                minHeight: 1024,
                maxHeight: 1792,
                supportedStyles: ["photorealistic", "artistic", "sketch", "painting"]
            ),
            ImageModel(
                id: "midjourney-v6",
                name: "Midjourney v6",
                provider: "Midjourney",
                description: "High detail image generation model",
                minWidth: 512,
                maxWidth: 1792,
                minHeight: 512,
                maxHeight: 1792,
                supportedStyles: ["photorealistic", "artistic", "concept-art", "illustration"]
            )
        ]
        
        return models
    }
}