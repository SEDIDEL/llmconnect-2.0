//
//  BotGalleryViewModel.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import Foundation
import SwiftUI
import Combine

// Bot and KnowledgeSource are already marked as Sendable in their class definitions

@MainActor
class BotGalleryViewModel: ObservableObject {
    @Published var bots: [Bot] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    
    private let botRepository: BotRepositoryProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Inicializar explícitamente todas las propiedades primero
        self.botRepository = ServiceLocator.shared.resolve()
        
        // Ahora podemos llamar a loadBots
        loadBots()
    }
    
    func loadBots() {
        isLoading = true
        
        Task {
            do {
                let allBots = try await botRepository.getBots()
                
                // Usar una copia local
                let botsToDisplay = allBots
                
                await MainActor.run {
                    self.bots = botsToDisplay
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = ErrorHandler.shared.getUserFriendlyMessage(from: error)
                    self.isLoading = false
                }
            }
        }
    }
    
    func createBot(name: String, emoji: String, description: String, systemPrompt: String, provider: AIProvider, model: String) -> Bot {
        let bot = Bot(
            name: name,
            emoji: emoji,
            botDescription: description,
            systemPrompt: systemPrompt,
            providerIdentifier: provider.rawValue,
            modelIdentifier: model
        )
        
        Task {
            do {
                try await botRepository.saveBot(bot)
                // Use Task.yield() instead of sleep
                await Task.yield()
                loadBots()
            } catch {
                Task { @MainActor in
                    self.errorMessage = ErrorHandler.shared.getUserFriendlyMessage(from: error)
                }
            }
        }
        
        return bot
    }
    
    func deleteBot(_ bot: Bot) {
        Task {
            do {
                try await botRepository.deleteBot(id: bot.id)
                // Use Task.yield() instead of sleep
                await Task.yield()
                loadBots()
            } catch {
                Task { @MainActor in
                    self.errorMessage = ErrorHandler.shared.getUserFriendlyMessage(from: error)
                }
            }
        }
    }
    
    func updateBot(_ bot: Bot) {
        Task {
            do {
                try await botRepository.saveBot(bot)
                // Use Task.yield() instead of sleep
                await Task.yield()
                loadBots()
            } catch {
                Task { @MainActor in
                    self.errorMessage = ErrorHandler.shared.getUserFriendlyMessage(from: error)
                }
            }
        }
    }
    
    func addKnowledgeSource(name: String, content: String, to bot: Bot) {
        let knowledgeSource = KnowledgeSource(name: name, content: content)
        
        Task {
            do {
                try await botRepository.addKnowledgeSource(knowledgeSource, to: bot.id)
                // Use Task.yield() instead of sleep
                await Task.yield()
                loadBots()
            } catch {
                Task { @MainActor in
                    self.errorMessage = ErrorHandler.shared.getUserFriendlyMessage(from: error)
                }
            }
        }
    }
    
    func removeKnowledgeSource(_ knowledgeSource: KnowledgeSource, from bot: Bot) {
        Task {
            do {
                try await botRepository.removeKnowledgeSource(id: knowledgeSource.id, from: bot.id)
                // Use Task.yield() instead of sleep
                await Task.yield()
                loadBots()
            } catch {
                Task { @MainActor in
                    self.errorMessage = ErrorHandler.shared.getUserFriendlyMessage(from: error)
                }
            }
        }
    }
    
    func updateBotSystemPrompt(bot: Bot, systemPrompt: String) {
        Task {
            do {
                try await botRepository.updateBotSystemPrompt(id: bot.id, systemPrompt: systemPrompt)
                // Use Task.yield() instead of sleep
                await Task.yield()
                loadBots()
            } catch {
                Task { @MainActor in
                    self.errorMessage = ErrorHandler.shared.getUserFriendlyMessage(from: error)
                }
            }
        }
    }
    
    func searchBots() {
        guard !searchText.isEmpty else {
            loadBots()
            return
        }
        
        Task {
            do {
                let results = try await botRepository.searchBots(query: searchText)
                
                // Usar una copia local
                let searchResults = results
                
                await MainActor.run {
                    self.bots = searchResults
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = ErrorHandler.shared.getUserFriendlyMessage(from: error)
                }
            }
        }
    }
}