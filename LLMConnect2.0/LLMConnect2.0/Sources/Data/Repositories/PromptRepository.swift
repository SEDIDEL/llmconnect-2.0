//
//  PromptRepository.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import Foundation
import SwiftData

@MainActor
class PromptRepository: PromptRepositoryProtocol {
    private let swiftDataManager: SwiftDataManager

    init() {
        self.swiftDataManager = SwiftDataManager.shared
    }
    
    func getPrompts() async throws -> [Prompt] {
        return try await swiftDataManager.fetch(
            Prompt.self,
            sortBy: [
                SortDescriptor(\Prompt.updatedAt, order: .reverse)
            ]
        )
    }

    func getPrompt(id: UUID) async throws -> Prompt {
        guard let prompt = try await swiftDataManager.fetchOne(
            Prompt.self,
            predicate: #Predicate<Prompt> { $0.id == id }
        ) else {
            throw DatabaseError.readFailed
        }

        return prompt
    }

    func savePrompt(_ prompt: Prompt) async throws {
        try await swiftDataManager.save()
    }
    
    func deletePrompt(id: UUID) async throws {
        guard let prompt = try await swiftDataManager.fetchOne(
            Prompt.self,
            predicate: #Predicate<Prompt> { $0.id == id }
        ) else {
            throw DatabaseError.deleteFailed
        }

        try await swiftDataManager.delete(prompt)
    }

    func updatePrompt(_ prompt: Prompt) async throws {
        prompt.updatedAt = Date()
        try await swiftDataManager.save()
    }

    func searchPrompts(query: String) async throws -> [Prompt] {
        let allPrompts = try await swiftDataManager.fetch(Prompt.self)
        
        let lowercaseQuery = query.lowercased()
        
        return allPrompts.filter { prompt in
            // Buscar en título
            if prompt.title.lowercased().contains(lowercaseQuery) {
                return true
            }
            
            // Buscar en contenido
            if prompt.content.lowercased().contains(lowercaseQuery) {
                return true
            }
            
            // Buscar en tags
            for tag in prompt.tags {
                if tag.lowercased().contains(lowercaseQuery) {
                    return true
                }
            }
            
            return false
        }
    }
    
    func getPromptCategories() async throws -> [PromptCategory] {
        return try await swiftDataManager.fetch(
            PromptCategory.self,
            sortBy: [
                SortDescriptor(\PromptCategory.name)
            ]
        )
    }

    func savePromptCategory(_ category: PromptCategory) async throws {
        try await swiftDataManager.save()
    }

    func deletePromptCategory(id: UUID) async throws {
        guard let category = try await swiftDataManager.fetchOne(
            PromptCategory.self,
            predicate: #Predicate<PromptCategory> { $0.id == id }
        ) else {
            throw DatabaseError.deleteFailed
        }

        try await swiftDataManager.delete(category)
    }

    func addPromptToCategory(promptID: UUID, categoryID: UUID) async throws {
        guard let prompt = try await swiftDataManager.fetchOne(
            Prompt.self,
            predicate: #Predicate<Prompt> { $0.id == promptID }
        ) else {
            throw DatabaseError.writeFailed
        }

        guard let category = try await swiftDataManager.fetchOne(
            PromptCategory.self,
            predicate: #Predicate<PromptCategory> { $0.id == categoryID }
        ) else {
            throw DatabaseError.writeFailed
        }

        if category.prompts == nil {
            category.prompts = []
        }

        prompt.category = category
        category.prompts?.append(prompt)

        try await swiftDataManager.save()
    }

    func removePromptFromCategory(promptID: UUID) async throws {
        guard let prompt = try await swiftDataManager.fetchOne(
            Prompt.self,
            predicate: #Predicate<Prompt> { $0.id == promptID }
        ) else {
            throw DatabaseError.writeFailed
        }

        if let category = prompt.category {
            category.prompts?.removeAll { $0.id == promptID }
        }

        prompt.category = nil

        try await swiftDataManager.save()
    }
}