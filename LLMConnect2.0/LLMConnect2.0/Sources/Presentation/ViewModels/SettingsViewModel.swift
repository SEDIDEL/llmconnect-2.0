//
//  SettingsViewModel.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import Foundation
import SwiftUI
import Combine

// Mark model as Sendable
extension SubscriptionTier: @unchecked Sendable {}

@MainActor
class SettingsViewModel: ObservableObject {
    // API Keys
    @Published var openAIKey: String = ""
    @Published var anthropicKey: String = ""
    @Published var groqKey: String = ""
    @Published var perplexityKey: String = ""
    @Published var deepSeekKey: String = ""
    @Published var openRouterKey: String = ""
    
    // Appearance settings
    @Published var appearance: Appearance = .system
    @Published var themeName: String = "Default"
    
    // Provider settings
    @Published var defaultProvider: AIProvider = .openAI
    @Published var customProviders: [CustomProvider] = []
    
    // Notification settings
    @Published var notificationsEnabled: Bool = true
    
    // Subscription status
    @Published var subscriptionStatus: SubscriptionTier = .free
    
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private let keychainManager = KeychainManager.shared
    private let userDefaults = UserDefaults.standard
    
    enum Appearance: String, CaseIterable, Identifiable {
        case system
        case light
        case dark
        
        var id: String { self.rawValue }
        
        var displayName: String {
            switch self {
            case .system: return "System"
            case .light: return "Light"
            case .dark: return "Dark"
            }
        }
    }
    
    struct CustomProvider {
        var id: UUID
        var name: String
        var baseURL: URL
        var apiKeyName: String
        var models: [CustomModel]
    }
    
    struct CustomModel {
        var id: String
        var name: String
        var maxTokens: Int
    }
    
    init() {
        loadSettings()
        loadAPIKeys()
        checkSubscriptionStatus()
    }
    
    private func loadSettings() {
        // Cargar configuración desde UserDefaults
        if let appearanceValue = userDefaults.string(forKey: "appearance"),
           let appearance = Appearance(rawValue: appearanceValue) {
            self.appearance = appearance
        }
        
        themeName = userDefaults.string(forKey: "themeName") ?? "Default"
        notificationsEnabled = userDefaults.bool(forKey: "notificationsEnabled")
        
        if let defaultProviderString = userDefaults.string(forKey: "defaultProvider"),
           let provider = AIProvider.allCases.first(where: { $0.rawValue == defaultProviderString }) {
            defaultProvider = provider
        }
        
        // Cargar proveedores personalizados (aquí se podría usar Codable para deserializar)
    }
    
    private func loadAPIKeys() {
        // Cargar claves API desde el keychain
        openAIKey = keychainManager.retrieveAPIKey(for: AIProvider.openAI.rawValue) ?? ""
        anthropicKey = keychainManager.retrieveAPIKey(for: AIProvider.anthropic.rawValue) ?? ""
        groqKey = keychainManager.retrieveAPIKey(for: AIProvider.groq.rawValue) ?? ""
        perplexityKey = keychainManager.retrieveAPIKey(for: AIProvider.perplexity.rawValue) ?? ""
        deepSeekKey = keychainManager.retrieveAPIKey(for: AIProvider.deepSeek.rawValue) ?? ""
        openRouterKey = keychainManager.retrieveAPIKey(for: AIProvider.openRouter.rawValue) ?? ""
    }
    
    private func checkSubscriptionStatus() {
        // En una implementación real, comprobaríamos el estado de la suscripción desde el SubscriptionManager
        Task {
            // Simulado para este ejemplo
            await MainActor.run {
                self.subscriptionStatus = .free
            }
        }
    }
    
    var hasAnyAPIKey: Bool {
        !openAIKey.isEmpty ||
        !anthropicKey.isEmpty ||
        !groqKey.isEmpty ||
        !perplexityKey.isEmpty ||
        !deepSeekKey.isEmpty ||
        !openRouterKey.isEmpty
    }
    
    func saveAPIKey(for provider: AIProvider, key: String) {
        guard !key.isEmpty else {
            errorMessage = "API key cannot be empty"
            return
        }
        
        do {
            try keychainManager.saveAPIKey(key, for: provider.rawValue)
            switch provider {
            case .openAI:
                openAIKey = key
            case .anthropic:
                anthropicKey = key
            case .groq:
                groqKey = key
            case .perplexity:
                perplexityKey = key
            case .deepSeek:
                deepSeekKey = key
            case .openRouter:
                openRouterKey = key
            case .custom:
                // Manejar proveedores personalizados
                break
            }
            
            errorMessage = nil
        } catch {
            errorMessage = "Failed to save API key: \(error.localizedDescription)"
        }
    }
    
    func deleteAPIKey(for provider: AIProvider) {
        do {
            try keychainManager.deleteAPIKey(for: provider.rawValue)
            switch provider {
            case .openAI:
                openAIKey = ""
            case .anthropic:
                anthropicKey = ""
            case .groq:
                groqKey = ""
            case .perplexity:
                perplexityKey = ""
            case .deepSeek:
                deepSeekKey = ""
            case .openRouter:
                openRouterKey = ""
            case .custom:
                // Manejar proveedores personalizados
                break
            }
            
            errorMessage = nil
        } catch {
            errorMessage = "Failed to delete API key: \(error.localizedDescription)"
        }
    }
    
    func validateAPIKey(for provider: AIProvider, key: String) async -> Bool {
        // En una implementación real, este método validaría la clave API con el proveedor
        // Este es un ejemplo simulado
        
        isLoading = true
        
        // Simulamos una llamada a la API
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 segundo
            
            // Validación básica (en realidad, necesitaríamos hacer una solicitud a la API)
            let isValid = !key.isEmpty && key.count > 10
            
            await MainActor.run {
                self.isLoading = false
            }
            
            return isValid
        } catch {
            await MainActor.run {
                self.errorMessage = "API key validation failed: \(error.localizedDescription)"
                self.isLoading = false
            }
            return false
        }
    }
    
    func saveAppearance() {
        userDefaults.set(appearance.rawValue, forKey: "appearance")
        userDefaults.set(themeName, forKey: "themeName")
    }
    
    func saveDefaultProvider() {
        userDefaults.set(defaultProvider.rawValue, forKey: "defaultProvider")
    }
    
    func saveNotificationSettings() {
        userDefaults.set(notificationsEnabled, forKey: "notificationsEnabled")
    }
    
    func saveCustomProvider(_ provider: CustomProvider) {
        // En una implementación real, guardaríamos los proveedores personalizados utilizando Codable
        // y UserDefaults o SwiftData
    }
    
    func deleteCustomProvider(id: UUID) {
        customProviders.removeAll { $0.id == id }
        // Luego guardar la lista actualizada
    }
    
    func restorePurchases() async {
        // En una implementación real, esto llamaría a restorePurchases() en SubscriptionManager
        isLoading = true
        
        do {
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 segundos
            
            await MainActor.run {
                self.isLoading = false
                // Actualizar estado de suscripción si se restaura
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}