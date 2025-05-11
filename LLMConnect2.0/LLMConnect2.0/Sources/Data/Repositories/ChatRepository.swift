//
//  ChatRepository.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import Foundation
import Combine

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, data: Data)
    case decodingError(Error)
    case missingAPIKey
    case invalidProvider
    case streamingNotSupported
}

enum DatabaseError: Error {
    case readFailed
    case writeFailed
    case deleteFailed
    case notFound
}

@MainActor
class ChatRepository: ChatRepositoryProtocol {
    private let dataManager = SwiftDataManager.shared
    private let apiClient: APIClient
    private let keychainManager = KeychainManager.shared

    init() {
        // Initialize with the default provider's base URL
        self.apiClient = APIClient(baseURL: AIProvider.openAI.baseURL)
    }

    func getChats() async throws -> [Chat] {
        // Fetch all chats from SwiftData
        return try await dataManager.fetch(
            Chat.self,
            sortBy: [
                SortDescriptor(\Chat.updatedAt, order: .reverse)
            ]
        )
    }

    func getChat(id: UUID) async throws -> Chat {
        // Fetch a specific chat by ID
        guard let chat = try await dataManager.fetchOne(
            Chat.self,
            predicate: #Predicate<Chat> { $0.id == id }
        ) else {
            throw DatabaseError.notFound
        }

        return chat
    }

    func saveChat(_ chat: Chat) async throws {
        // Save the chat to SwiftData
        try await dataManager.save()
    }

    func deleteChat(id: UUID) async throws {
        // Find and delete the chat
        guard let chat = try await dataManager.fetchOne(
            Chat.self,
            predicate: #Predicate<Chat> { $0.id == id }
        ) else {
            throw DatabaseError.notFound
        }

        try await dataManager.delete(chat)
    }
    
    func sendMessage(_ message: Message, in chatID: UUID) async throws -> Message {
        // First, find the chat
        let chat = try await getChat(id: chatID)

        // Add the user message to the chat
        chat.messages.append(message)
        chat.updatedAt = Date()
        try await saveChat(chat)

        // Get the provider information
        let providerString = chat.providerIdentifier
        guard let provider = AIProvider(rawValue: providerString) else {
            throw APIError.invalidProvider
        }

        // Get the API key from the keychain
        let apiKey = keychainManager.retrieveAPIKey(for: providerString) ?? ""
        if apiKey.isEmpty {
            throw APIError.missingAPIKey
        }

        // Prepare the request
        let apiClient = APIClient(baseURL: provider.baseURL)

        // Create a response message
        let assistantMessage = Message(role: .assistant, content: "Thinking...")
        chat.messages.append(assistantMessage)
        try await saveChat(chat)

        // Create a sequence of all previous messages for context
        let chatHistory = chat.messages.sorted { $0.timestamp < $1.timestamp }

        do {
            // This is a simplified implementation - in a real app, you would use proper API calls
            // based on the provider and handle their specific response formats

            // For now, we'll create a simplified response
            let response = "I'm a functional AI assistant. This is a response to your message: \"\(message.content)\""
            assistantMessage.content = response
            chat.updatedAt = Date()
            try await saveChat(chat)

            return assistantMessage
        } catch {
            // In case of an error, update the message to show the error
            assistantMessage.content = "Error: \(error.localizedDescription)"
            try await saveChat(chat)
            throw error
        }
    }

    nonisolated func streamMessage(_ message: Message, in chatID: UUID) -> AsyncThrowingStream<MessageChunk, Error> {
        return AsyncThrowingStream { continuation in
            // Since this is a nonisolated method,
            // we'll handle the main actor access safely within the task
            Task.detached {
                do {
                    // This needs to be run on the main actor since it accesses SwiftData
                    let chat = try await MainActor.run { try await self.getChat(id: chatID) }

                    // Add the user message to the chat
                    await MainActor.run {
                        chat.messages.append(message)
                        chat.updatedAt = Date()
                    }
                    try await MainActor.run { try await self.saveChat(chat) }

                    // Get the provider information
                    let providerString = chat.providerIdentifier
                    guard let provider = AIProvider(rawValue: providerString) else {
                        throw APIError.invalidProvider
                    }

                    // Prepare response message
                    let assistantMessage = Message(role: .assistant, content: "")
                    await MainActor.run {
                        chat.messages.append(assistantMessage)
                    }
                    try await MainActor.run { try await self.saveChat(chat) }

                    // For demonstration, we'll create a simple response
                    let response = "I'm a functional AI assistant responding in a stream. I received your message: \"\(message.content)\" and I'm here to help with any questions you have about using AI models or their integrations."

                    // Stream the response character by character
                    var fullResponse = ""
                    for i in 0..<response.count {
                        let index = response.index(response.startIndex, offsetBy: i)
                        let char = String(response[index])
                        fullResponse += char

                        let chunk = MessageChunk(
                            id: UUID(),
                            content: char,
                            isComplete: i == response.count - 1
                        )
                        continuation.yield(chunk)

                        // Update the message content as we go
                        await MainActor.run {
                            assistantMessage.content = fullResponse
                        }

                        // If this is the last character, save the chat
                        if i == response.count - 1 {
                            await MainActor.run {
                                chat.updatedAt = Date()
                            }
                            try await MainActor.run { try await self.saveChat(chat) }
                        }

                        // Simulate typing delay
                        try await Task.sleep(nanoseconds: 30_000_000)
                    }

                    // Complete the stream
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    func updateChatTitle(id: UUID, title: String) async throws {
        // Find the chat
        let chat = try await getChat(id: id)

        // Update the title
        chat.title = title
        chat.updatedAt = Date()

        // Save changes
        try await saveChat(chat)
    }

    func pinChat(id: UUID, isPinned: Bool) async throws {
        // Find the chat
        let chat = try await getChat(id: id)

        // Update the pinned status
        chat.isPinned = isPinned
        chat.updatedAt = Date()

        // Save changes
        try await saveChat(chat)
    }

    func archiveChat(id: UUID, isArchived: Bool) async throws {
        // Find the chat
        let chat = try await getChat(id: id)

        // Update the archived status
        chat.isArchived = isArchived
        chat.updatedAt = Date()

        // Save changes
        try await saveChat(chat)
    }

    func moveChat(id: UUID, to folderID: UUID?) async throws {
        // Find the chat
        let chat = try await getChat(id: id)

        if let folderID = folderID {
            // Find the folder
            guard let folder = try await dataManager.fetchOne(
                Folder.self,
                predicate: #Predicate<Folder> { $0.id == folderID }
            ) else {
                throw DatabaseError.notFound
            }

            // Initialize folders array if nil
            if chat.folders == nil {
                chat.folders = []
            }

            // Add the folder if not already present
            if !chat.folders!.contains(where: { $0.id == folder.id }) {
                chat.folders!.append(folder)
            }
        } else {
            // Remove from all folders
            chat.folders = []
        }

        chat.updatedAt = Date()

        // Save changes
        try await saveChat(chat)
    }

    func searchChats(query: String) async throws -> [Chat] {
        // Get all chats first
        let allChats = try await getChats()

        // Filter chats that match the query
        return allChats.filter { chat in
            // Match against chat title
            if let title = chat.title, title.localizedCaseInsensitiveContains(query) {
                return true
            }

            // Match against message content
            if chat.messages.contains(where: { message in
                message.content.localizedCaseInsensitiveContains(query)
            }) {
                return true
            }

            return false
        }
    }

    func getFolders() async throws -> [Folder] {
        // Fetch all folders from SwiftData
        return try await dataManager.fetch(
            Folder.self,
            sortBy: [
                SortDescriptor(\Folder.name)
            ]
        )
    }

    func createFolder(_ folder: Folder) async throws {
        // Save the folder to SwiftData
        try await dataManager.save()
    }
}