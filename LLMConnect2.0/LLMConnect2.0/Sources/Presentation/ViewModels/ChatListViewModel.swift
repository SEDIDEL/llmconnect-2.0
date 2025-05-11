//
//  ChatListViewModel.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import Foundation
import SwiftUI
import Combine
import OSLog

// Chat is already marked as Sendable in its class definition

@MainActor
class ChatListViewModel: ObservableObject {
    @Published var chats: [Chat] = []
    @Published var folders: [Folder] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    @Published var selectedFolder: Folder?
    @Published var showingArchived: Bool = false
    
    private let chatRepository: ChatRepositoryProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Inicializar explícitamente todas las propiedades primero
        self.chatRepository = ServiceLocator.shared.resolve()
        
        // Ahora podemos llamar a los métodos
        loadChats()
        loadFolders()
    }
    
    func loadChats() {
        isLoading = true
        
        Task {
            do {
                let allChats = try await chatRepository.getChats()
                
                // Usamos una copia local para evitar capturar la variable directamente
                let chatsToShow = allChats.filter { chat in
                    // Filtrar por archivados según el estado actual
                    if showingArchived {
                        return chat.isArchived
                    } else {
                        return !chat.isArchived
                    }
                }
                
                await MainActor.run {
                    self.chats = chatsToShow
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
    
    func loadFolders() {
        Task {
            do {
                let folders = try await chatRepository.getFolders()
                
                // Usar una copia local
                let foldersToShow = folders
                
                await MainActor.run {
                    self.folders = foldersToShow
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = ErrorHandler.shared.getUserFriendlyMessage(from: error)
                }
            }
        }
    }
    
    func createNewChat(provider: AIProvider, model: String) -> Chat {
        // Crear un nuevo chat con fecha actualizada
        let chat = Chat(
            providerIdentifier: provider.rawValue,
            modelIdentifier: model
        )

        // Mensajes informativos para debug
        print("Creating new chat with ID: \(chat.id)")
        print("Provider: \(provider.rawValue), Model: \(model)")

        // Guardar el chat de forma asíncrona
        Task {
            do {
                try await chatRepository.saveChat(chat)
                print("Chat saved successfully with ID: \(chat.id)")

                // Use Task.yield() instead of sleep
                await Task.yield()
                loadChats()
            } catch {
                print("Error saving chat: \(error.localizedDescription)")
                Task { @MainActor in
                    self.errorMessage = ErrorHandler.shared.getUserFriendlyMessage(from: error)
                }
            }
        }

        return chat
    }
    
    func deleteChat(_ chat: Chat) {
        Task {
            do {
                try await chatRepository.deleteChat(id: chat.id)
                // Use Task.yield() instead of sleep
                await Task.yield()
                loadChats()
            } catch {
                Task { @MainActor in
                    self.errorMessage = ErrorHandler.shared.getUserFriendlyMessage(from: error)
                }
            }
        }
    }
    
    func toggleArchiveChat(_ chat: Chat) {
        Task {
            do {
                try await chatRepository.archiveChat(id: chat.id, isArchived: !chat.isArchived)
                // Use Task.yield() instead of sleep
                await Task.yield()
                loadChats()
            } catch {
                Task { @MainActor in
                    self.errorMessage = ErrorHandler.shared.getUserFriendlyMessage(from: error)
                }
            }
        }
    }
    
    func pinChat(_ chat: Chat) {
        Task {
            do {
                try await chatRepository.pinChat(id: chat.id, isPinned: !chat.isPinned)
                // Use Task.yield() instead of sleep
                await Task.yield()
                loadChats()
            } catch {
                Task { @MainActor in
                    self.errorMessage = ErrorHandler.shared.getUserFriendlyMessage(from: error)
                }
            }
        }
    }
    
    func moveChat(_ chat: Chat, to folder: Folder?) {
        Task {
            do {
                try await chatRepository.moveChat(id: chat.id, to: folder?.id)
                // Use Task.yield() instead of sleep
                await Task.yield()
                loadChats()
            } catch {
                Task { @MainActor in
                    self.errorMessage = ErrorHandler.shared.getUserFriendlyMessage(from: error)
                }
            }
        }
    }
    
    func createFolder(name: String, color: String) {
        let folder = Folder(name: name, color: color)
        
        Task {
            do {
                try await chatRepository.createFolder(folder)
                // Use Task.yield() instead of sleep
                await Task.yield()
                loadFolders()
            } catch {
                Task { @MainActor in
                    self.errorMessage = ErrorHandler.shared.getUserFriendlyMessage(from: error)
                }
            }
        }
    }
    
    func searchChats() {
        guard !searchText.isEmpty else {
            loadChats()
            return
        }
        
        Task {
            do {
                let results = try await chatRepository.searchChats(query: searchText)
                
                // Usar una copia local
                let filteredChats = results.filter { chat in
                    if showingArchived {
                        return chat.isArchived
                    } else {
                        return !chat.isArchived
                    }
                }
                
                await MainActor.run {
                    self.chats = filteredChats
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = ErrorHandler.shared.getUserFriendlyMessage(from: error)
                }
            }
        }
    }
    
    func toggleShowArchived() {
        showingArchived.toggle()
        loadChats()
    }
    
    func selectFolder(_ folder: Folder?) {
        selectedFolder = folder

        Task {
            do {
                let allChats = try await chatRepository.getChats()

                // Usar una copia local
                let filteredChats: [Chat]

                if let folder = folder {
                    // Filtrar chats por carpeta
                    filteredChats = allChats.filter { chat in
                        guard let folders = chat.folders else { return false }
                        return folders.contains { $0.id == folder.id }
                    }.filter { chat in
                        // Mantener el filtro de archivados
                        if showingArchived {
                            return chat.isArchived
                        } else {
                            return !chat.isArchived
                        }
                    }
                } else {
                    // Filtrar solo por archivados
                    filteredChats = allChats.filter { chat in
                        if showingArchived {
                            return chat.isArchived
                        } else {
                            return !chat.isArchived
                        }
                    }
                }

                await MainActor.run {
                    self.chats = filteredChats
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = ErrorHandler.shared.getUserFriendlyMessage(from: error)
                }
            }
        }
    }
}