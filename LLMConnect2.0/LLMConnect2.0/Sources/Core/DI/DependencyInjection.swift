//
//  DependencyInjection.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import Foundation

/// Centralizes all dependency registrations to ensure they're set up properly
@MainActor
final class DependencyInjection {
    @MainActor
    static func registerAllServices() {
        let serviceLocator = ServiceLocator.shared
        
        // Register repositories
        serviceLocator.register(ChatRepositoryProtocol.self) {
            return ChatRepository()
        }
        
        serviceLocator.register(BotRepositoryProtocol.self) {
            return BotRepository()
        }
        
        serviceLocator.register(MemoryRepositoryProtocol.self) {
            return MemoryRepository()
        }
        
        serviceLocator.register(ImageGenerationRepositoryProtocol.self) {
            return ImageGenerationRepository()
        }
        
        serviceLocator.register(PromptRepositoryProtocol.self) {
            return PromptRepository()
        }
        
        // Register use cases
        serviceLocator.register(SendMessageUseCase.self) {
            return SendMessageUseCase(chatRepository: serviceLocator.resolve())
        }
        
        serviceLocator.register(GenerateImageUseCase.self) {
            return GenerateImageUseCase(imageRepository: serviceLocator.resolve())
        }

        // Register services
        serviceLocator.register(AIProviderServiceProtocol.self) {
            return AIProviderService()
        }
    }
}