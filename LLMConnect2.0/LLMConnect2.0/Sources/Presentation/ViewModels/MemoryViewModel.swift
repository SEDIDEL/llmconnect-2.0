//
//  MemoryViewModel.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import Foundation
import SwiftUI
import Combine

// Memory already conforms to Sendable in Memory.swift

@MainActor
class MemoryViewModel: ObservableObject {
    @Published var memories: [Memory] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    
    // Cambiamos de @Inject a una propiedad normal
    private let memoryRepository: MemoryRepositoryProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Inicializamos directamente la propiedad sin tratar de asignarla a través de @Inject
        self.memoryRepository = ServiceLocator.shared.resolve()
        
        // Ahora es seguro llamar a loadMemories
        loadMemories()
    }
    
    func loadMemories() {
        isLoading = true
        
        Task {
            do {
                let allMemories = try await memoryRepository.getMemories()
                
                // Copy to avoid capturing the variable directly
                let memoriesToUpdate = allMemories
                
                await MainActor.run {
                    self.memories = memoriesToUpdate
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
    
    func createMemory(title: String, content: String, tags: [String] = []) -> Memory {
        let memory = Memory(title: title, content: content, tags: tags)
        
        Task {
            do {
                try await memoryRepository.saveMemory(memory)
                // Use an async operation
                try await Task.sleep(nanoseconds: 1) // Tiny sleep to make it async
                loadMemories()
            } catch {
                Task { @MainActor in
                    self.errorMessage = ErrorHandler.shared.getUserFriendlyMessage(from: error)
                }
            }
        }
        
        return memory
    }
    
    func deleteMemory(_ memory: Memory) {
        Task {
            do {
                try await memoryRepository.deleteMemory(id: memory.id)
                // Use an async operation
                try await Task.sleep(nanoseconds: 1) // Tiny sleep to make it async
                loadMemories()
            } catch {
                Task { @MainActor in
                    self.errorMessage = ErrorHandler.shared.getUserFriendlyMessage(from: error)
                }
            }
        }
    }
    
    func updateMemory(_ memory: Memory) {
        Task {
            do {
                try await memoryRepository.updateMemory(memory)
                // Use an async operation
                try await Task.sleep(nanoseconds: 1) // Tiny sleep to make it async
                loadMemories()
            } catch {
                Task { @MainActor in
                    self.errorMessage = ErrorHandler.shared.getUserFriendlyMessage(from: error)
                }
            }
        }
    }
    
    func searchMemories() {
        guard !searchText.isEmpty else {
            loadMemories()
            return
        }
        
        Task {
            do {
                let results = try await memoryRepository.searchMemories(query: searchText)
                
                // Copy to avoid capturing the variable directly
                let memoriesToUpdate = results
                
                await MainActor.run {
                    self.memories = memoriesToUpdate
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = ErrorHandler.shared.getUserFriendlyMessage(from: error)
                }
            }
        }
    }
    
    func findRelevantMemories(for text: String, limit: Int = 5) async -> [Memory] {
        do {
            return try await memoryRepository.findRelevantMemories(for: text, limit: limit)
        } catch {
            Task { @MainActor in
                self.errorMessage = ErrorHandler.shared.getUserFriendlyMessage(from: error)
            }
            return []
        }
    }
}