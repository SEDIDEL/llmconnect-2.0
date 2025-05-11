//
//  MemoryRepository.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import Foundation
import SwiftData

@MainActor
class MemoryRepository: MemoryRepositoryProtocol {
    private let swiftDataManager: SwiftDataManager

    init() {
        self.swiftDataManager = SwiftDataManager.shared
    }
    
    func getMemories() async throws -> [Memory] {
        return try await swiftDataManager.fetch(
            Memory.self,
            sortBy: [
                SortDescriptor(\Memory.updatedAt, order: .reverse)
            ]
        )
    }

    func getMemory(id: UUID) async throws -> Memory {
        guard let memory = try await swiftDataManager.fetchOne(
            Memory.self,
            predicate: #Predicate<Memory> { $0.id == id }
        ) else {
            throw DatabaseError.readFailed
        }

        return memory
    }

    func saveMemory(_ memory: Memory) async throws {
        try await swiftDataManager.save()
    }

    func deleteMemory(id: UUID) async throws {
        guard let memory = try await swiftDataManager.fetchOne(
            Memory.self,
            predicate: #Predicate<Memory> { $0.id == id }
        ) else {
            throw DatabaseError.deleteFailed
        }

        try await swiftDataManager.delete(memory)
    }

    func updateMemory(_ memory: Memory) async throws {
        memory.updatedAt = Date()
        try await swiftDataManager.save()
    }

    func searchMemories(query: String) async throws -> [Memory] {
        let allMemories = try await swiftDataManager.fetch(Memory.self)
        
        let lowercaseQuery = query.lowercased()
        
        return allMemories.filter { memory in
            // Buscar en título
            if memory.title.lowercased().contains(lowercaseQuery) {
                return true
            }
            
            // Buscar en contenido
            if memory.content.lowercased().contains(lowercaseQuery) {
                return true
            }
            
            // Buscar en tags
            for tag in memory.tags {
                if tag.lowercased().contains(lowercaseQuery) {
                    return true
                }
            }
            
            return false
        }
    }
    
    func findRelevantMemories(for text: String, limit: Int) async throws -> [Memory] {
        // En una implementación real, esto utilizaría embeddings vectoriales y búsqueda semántica
        // Esta es una implementación simplificada basada en coincidencia de palabras clave

        let keywords = extractKeywords(from: text)
        let allMemories = try await swiftDataManager.fetch(Memory.self)
        
        var scoredMemories: [(memory: Memory, score: Int)] = []
        
        for memory in allMemories {
            let score = calculateRelevanceScore(memory: memory, keywords: keywords)
            if score > 0 {
                scoredMemories.append((memory, score))
            }
        }
        
        // Ordenar por puntuación (de mayor a menor) y limitar el número de resultados
        let sortedMemories = scoredMemories.sorted { $0.score > $1.score }.map { $0.memory }
        return Array(sortedMemories.prefix(limit))
    }
    
    // MARK: - Métodos privados
    
    private func extractKeywords(from text: String) -> [String] {
        // Simplificado: dividir en palabras y filtrar artículos comunes
        let stopWords = ["a", "an", "the", "and", "or", "but", "to", "in", "on", "at", "for", "with", "by", "of"]
        
        return text.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 2 && !stopWords.contains($0) }
    }
    
    private func calculateRelevanceScore(memory: Memory, keywords: [String]) -> Int {
        var score = 0
        
        // Buscar en título
        for keyword in keywords {
            if memory.title.lowercased().contains(keyword) {
                score += 3  // Mayor peso para coincidencias en el título
            }
        }
        
        // Buscar en contenido
        for keyword in keywords {
            if memory.content.lowercased().contains(keyword) {
                score += 1
            }
        }
        
        // Buscar en tags
        for tag in memory.tags {
            if keywords.contains(tag.lowercased()) {
                score += 5  // Mayor peso para coincidencias exactas en tags
            }
        }
        
        return score
    }
}