//
//  PromptRepositoryProtocol.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import Foundation

protocol PromptRepositoryProtocol {
    func getPrompts() async throws -> [Prompt]
    func getPrompt(id: UUID) async throws -> Prompt
    func savePrompt(_ prompt: Prompt) async throws
    func deletePrompt(id: UUID) async throws
    func updatePrompt(_ prompt: Prompt) async throws
    func searchPrompts(query: String) async throws -> [Prompt]
    
    func getPromptCategories() async throws -> [PromptCategory]
    func savePromptCategory(_ category: PromptCategory) async throws
    func deletePromptCategory(id: UUID) async throws
    
    func addPromptToCategory(promptID: UUID, categoryID: UUID) async throws
    func removePromptFromCategory(promptID: UUID) async throws
}