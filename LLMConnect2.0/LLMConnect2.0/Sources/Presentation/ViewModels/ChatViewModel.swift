//
//  ChatViewModel.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import Foundation
import SwiftUI
import Combine
import OSLog

// MessageChunk already conforms to Sendable in ChatRepositoryProtocol.swift

@MainActor
class ChatViewModel: ObservableObject {
    // Input state
    @Published var inputMessage: String = ""
    
    // Chat state
    @Published var chatTitle: String = "Chat"
    @Published var messages: [Message] = []
    @Published var folders: [Folder] = []
    @Published var isPinned: Bool = false
    
    // UI state
    @Published var isStreaming: Bool = false
    @Published var isSending: Bool = false
    @Published var streamingMessage: String = ""
    @Published var isShowingRenameDialog: Bool = false
    @Published var isShowingDeleteConfirmation: Bool = false
    @Published var isShowingNewFolderDialog: Bool = false
    @Published var isShowingError: Bool = false
    
    // Dialog state
    @Published var newChatTitle: String = ""
    @Published var newFolderName: String = ""
    @Published var errorMessage: String = ""
    
    private let chat: Chat
    private let sendMessageUseCase: SendMessageUseCase
    private let chatRepository: ChatRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    private var streamCancellable: AnyCancellable?
    
    init(chat: Chat) {
        self.chat = chat
        self.chatTitle = chat.title ?? "Chat"
        self.isPinned = chat.isPinned
        self.chatRepository = ServiceLocator.shared.resolve()
        self.sendMessageUseCase = SendMessageUseCase(chatRepository: self.chatRepository)

        // Asegurarse de que el chat se guarde al inicio
        Task {
            do {
                try await chatRepository.saveChat(chat)
                print("Chat guardado en init: \(chat.id)")
            } catch {
                print("Error guardando chat en init: \(error.localizedDescription)")
                showError(error: error)
            }
        }

        loadMessages()
        loadFolders()
    }
    
    private func loadMessages() {
        messages = chat.messages.sorted { $0.timestamp < $1.timestamp }
    }
    
    private func loadFolders() {
        Task {
            do {
                let allFolders = try await chatRepository.getFolders()
                let foldersToShow = allFolders
                
                await MainActor.run {
                    self.folders = foldersToShow
                }
            } catch {
                await MainActor.run {
                    self.showError(error: error)
                }
            }
        }
    }
    
    func sendMessage() {
        guard !inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = Message(role: .user, content: inputMessage)
        messages.append(userMessage)
        
        let messageToSend = inputMessage
        inputMessage = ""
        isSending = true
        isStreaming = true
        streamingMessage = ""
        
        Task {
            do {
                if chat.title == nil {
                    // Generate title for new chat
                    try await generateChatTitle(from: messageToSend)
                }
                
                let stream = sendMessageUseCase.executeStream(
                    message: userMessage,
                    in: chat.id
                )

                // Handle streaming with AsyncThrowingStream
                Task {
                    do {
                        for try await chunk in stream {
                            await MainActor.run {
                                self.streamingMessage += chunk.content
                            }
                        }

                        // Completion handling
                        await MainActor.run {
                            if !self.streamingMessage.isEmpty {
                                self.messages.append(
                                    Message(role: .assistant, content: self.streamingMessage)
                                )
                            }

                            self.isStreaming = false
                            self.isSending = false
                            self.streamingMessage = ""
                        }
                    } catch {
                        await MainActor.run {
                            self.showError(error: error)
                            self.isStreaming = false
                            self.isSending = false
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.showError(error: error)
                    self.isStreaming = false
                    self.isSending = false
                }
            }
        }
    }
    
    private func generateChatTitle(from message: String) async throws {
        // This would use an AI provider to generate a title
        // For now, just use the first few words of the message
        let words = message.split(separator: " ")
        let titleWords = words.prefix(3).joined(separator: " ")
        let title = titleWords.count > 15 ? "\(titleWords)..." : titleWords
        
        try await chatRepository.updateChatTitle(id: chat.id, title: String(title))
        
        await MainActor.run {
            self.chatTitle = String(title)
        }
    }
    
    func renameChat() {
        newChatTitle = chatTitle
        isShowingRenameDialog = true
    }
    
    func confirmRename() {
        guard !newChatTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        Task {
            do {
                try await chatRepository.updateChatTitle(id: chat.id, title: newChatTitle)
                
                await MainActor.run {
                    self.chatTitle = self.newChatTitle
                }
            } catch {
                await MainActor.run {
                    self.showError(error: error)
                }
            }
        }
    }
    
    func pinChat(_ isPinned: Bool) {
        Task {
            do {
                try await chatRepository.pinChat(id: chat.id, isPinned: isPinned)
                
                await MainActor.run {
                    self.isPinned = isPinned
                }
            } catch {
                await MainActor.run {
                    self.showError(error: error)
                }
            }
        }
    }
    
    func shareChat() {
        // Implementation would involve creating a shareable format of the chat
    }
    
    func moveChat(to folderID: UUID) {
        Task {
            do {
                try await chatRepository.moveChat(id: chat.id, to: folderID)
            } catch {
                await MainActor.run {
                    self.showError(error: error)
                }
            }
        }
    }
    
    func createNewFolder() {
        newFolderName = ""
        isShowingNewFolderDialog = true
    }
    
    func confirmNewFolder() {
        guard !newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        Task {
            do {
                let folder = Folder(name: newFolderName, color: "blue")
                try await chatRepository.createFolder(folder)
                
                // Reload folders - use yield instead of sleep
                await Task.yield()
                loadFolders()
            } catch {
                await MainActor.run {
                    self.showError(error: error)
                }
            }
        }
    }
    
    func deleteChat() {
        isShowingDeleteConfirmation = true
    }
    
    func confirmDelete() {
        Task {
            do {
                try await chatRepository.deleteChat(id: chat.id)
                
                // Navigation would be handled by coordinator
            } catch {
                await MainActor.run {
                    self.showError(error: error)
                }
            }
        }
    }
    
    private func showError(error: Error) {
        errorMessage = ErrorHandler.shared.getUserFriendlyMessage(from: error)
        isShowingError = true
        
        // Log the error
        ErrorHandler.shared.handle(error: error)
    }
}