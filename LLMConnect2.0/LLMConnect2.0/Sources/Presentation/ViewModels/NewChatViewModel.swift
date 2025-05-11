//
//  NewChatViewModel.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class NewChatViewModel: ObservableObject {
    @Published var selectedProvider: AIProvider = .openAI
    @Published var selectedModelId: String = "gpt-4o"
    @Published var availableModels: [AIModelInfo] = []
    @Published var isLoadingModels: Bool = false
    @Published var errorMessage: String?
    
    private let aiProviderService: AIProviderServiceProtocol
    private let keychainManager = KeychainManager.shared
    
    init(aiProviderService: AIProviderServiceProtocol = ServiceLocator.shared.resolve()) {
        self.aiProviderService = aiProviderService
        self.availableModels = aiProviderService.defaultModels(for: selectedProvider)
        
        // Asegurarse de que selectedModelId existe en availableModels
        if let firstModel = availableModels.first {
            selectedModelId = firstModel.id
        }
        
        // Cargar los modelos del proveedor seleccionado
        loadModelsForCurrentProvider()
    }
    
    func loadModelsForCurrentProvider() {
        // Cargar modelos por defecto inmediatamente
        self.availableModels = aiProviderService.defaultModels(for: selectedProvider)
        
        // Si hay un modelo por defecto, seleccionarlo
        if let firstModel = availableModels.first {
            selectedModelId = firstModel.id
        }
        
        // Recuperar la clave API del proveedor seleccionado
        let apiKey = keychainManager.retrieveAPIKey(for: selectedProvider.rawValue) ?? ""
        
        // Si hay una clave API, intentar cargar los modelos del proveedor
        if !apiKey.isEmpty {
            isLoadingModels = true
            
            Task {
                do {
                    let models = try await aiProviderService.fetchAvailableModels(provider: selectedProvider, apiKey: apiKey)
                    
                    await MainActor.run {
                        self.availableModels = models
                        self.isLoadingModels = false
                        
                        // Asegurarse de que selectedModelId existe en los nuevos availableModels
                        if !models.contains(where: { $0.id == selectedModelId }), let firstModel = models.first {
                            selectedModelId = firstModel.id
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.errorMessage = "No se pudieron cargar los modelos: \(error.localizedDescription)"
                        self.isLoadingModels = false
                    }
                }
            }
        }
    }
    
    func providerChanged() {
        loadModelsForCurrentProvider()
    }
    
    func modelName(for modelId: String) -> String {
        if let model = availableModels.first(where: { $0.id == modelId }) {
            return model.name
        }
        return modelId
    }
}