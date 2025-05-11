//
//  BotRepository.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import Foundation
import SwiftData

@MainActor
class BotRepository: BotRepositoryProtocol {
    private let swiftDataManager: SwiftDataManager

    init() {
        self.swiftDataManager = SwiftDataManager.shared
    }
    
    func getBots() async throws -> [Bot] {
        return try await swiftDataManager.fetch(
            Bot.self,
            sortBy: [
                SortDescriptor(\Bot.name)
            ]
        )
    }
    
    func getBot(id: UUID) async throws -> Bot {
        guard let bot = try await swiftDataManager.fetchOne(
            Bot.self,
            predicate: #Predicate<Bot> { $0.id == id }
        ) else {
            throw DatabaseError.readFailed
        }
        
        return bot
    }
    
    func saveBot(_ bot: Bot) async throws {
        try await swiftDataManager.save()
    }
    
    func deleteBot(id: UUID) async throws {
        guard let bot = try await swiftDataManager.fetchOne(
            Bot.self,
            predicate: #Predicate<Bot> { $0.id == id }
        ) else {
            throw DatabaseError.deleteFailed
        }

        try await swiftDataManager.delete(bot)
    }
    
    func addKnowledgeSource(_ source: KnowledgeSource, to botID: UUID) async throws {
        guard let bot = try await swiftDataManager.fetchOne(
            Bot.self,
            predicate: #Predicate<Bot> { $0.id == botID }
        ) else {
            throw DatabaseError.writeFailed
        }
        
        if bot.knowledgeSources == nil {
            bot.knowledgeSources = []
        }
        
        bot.knowledgeSources?.append(source)
        bot.updatedAt = Date()

        try await swiftDataManager.save()
    }
    
    func removeKnowledgeSource(id: UUID, from botID: UUID) async throws {
        guard let bot = try await swiftDataManager.fetchOne(
            Bot.self,
            predicate: #Predicate<Bot> { $0.id == botID }
        ) else {
            throw DatabaseError.writeFailed
        }
        
        bot.knowledgeSources?.removeAll { $0.id == id }
        bot.updatedAt = Date()

        try await swiftDataManager.save()
    }
    
    func updateBotSystemPrompt(id: UUID, systemPrompt: String) async throws {
        guard let bot = try await swiftDataManager.fetchOne(
            Bot.self,
            predicate: #Predicate<Bot> { $0.id == id }
        ) else {
            throw DatabaseError.writeFailed
        }
        
        bot.systemPrompt = systemPrompt
        bot.updatedAt = Date()

        try await swiftDataManager.save()
    }
    
    func searchBots(query: String) async throws -> [Bot] {
        // Implementación de búsqueda simplificada
        let allBots = try await swiftDataManager.fetch(Bot.self)
        
        let lowercaseQuery = query.lowercased()
        
        return allBots.filter { bot in
            // Buscar en nombre
            if bot.name.lowercased().contains(lowercaseQuery) {
                return true
            }
            
            // Buscar en descripción
            if bot.botDescription.lowercased().contains(lowercaseQuery) {
                return true
            }
            
            // Buscar en prompt del sistema
            if bot.systemPrompt.lowercased().contains(lowercaseQuery) {
                return true
            }
            
            // Buscar en fuentes de conocimiento
            if let knowledgeSources = bot.knowledgeSources {
                for source in knowledgeSources {
                    if source.name.lowercased().contains(lowercaseQuery) ||
                       source.content.lowercased().contains(lowercaseQuery) {
                        return true
                    }
                }
            }
            
            return false
        }
    }
}