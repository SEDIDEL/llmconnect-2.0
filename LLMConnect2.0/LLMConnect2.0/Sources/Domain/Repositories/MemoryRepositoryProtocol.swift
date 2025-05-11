//
//  MemoryRepositoryProtocol.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import Foundation

protocol MemoryRepositoryProtocol {
    func getMemories() async throws -> [Memory]
    func getMemory(id: UUID) async throws -> Memory
    func saveMemory(_ memory: Memory) async throws
    func deleteMemory(id: UUID) async throws
    func updateMemory(_ memory: Memory) async throws
    func searchMemories(query: String) async throws -> [Memory]
    func findRelevantMemories(for text: String, limit: Int) async throws -> [Memory]
}