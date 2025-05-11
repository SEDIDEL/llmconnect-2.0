//
//  ChatRepository.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import Foundation
import Combine

// APIError y DatabaseError ya están definidos en los archivos correspondientes

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
        // Asegurarse de que el chat tenga su updateAt actualizado
        chat.updatedAt = Date()

        // Guardar en la base de datos
        print("Saving chat: \(chat.id)")
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

        // Actualizar la URL base según el proveedor
        self.apiClient.baseURL = provider.baseURL

        // Create a response message
        let assistantMessage = Message(role: .assistant, content: "Thinking...")
        chat.messages.append(assistantMessage)
        try await saveChat(chat)

        // Create a sequence of all previous messages for context
        let chatHistory = chat.messages.sorted { $0.timestamp < $1.timestamp }

        // Crear un saludo basado en la historia de la conversación
        let greeting = chatHistory.count > 2 ? "Continuando nuestra conversación" : "Iniciando una nueva conversación"

        do {
            // This is a simplified implementation - in a real app, you would use proper API calls
            // based on the provider and handle their specific response formats

            // For now, we'll create a simplified response using the chat history
            let response = "\(greeting). I'm a functional AI assistant. This is a response to your message: \"\(message.content)\""
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
                    // Primero, obtenemos el ID del chat para uso local
                    let chatIDLocal = chatID

                    // Usar withCheckedThrowingContinuation para hacer la llamada al MainActor
                    let chat = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Chat, Error>) in
                        Task { @MainActor in
                            do {
                                let result = try await self.getChat(id: chatIDLocal)
                                continuation.resume(returning: result)
                            } catch {
                                continuation.resume(throwing: error)
                            }
                        }
                    }

                    // Add the user message to the chat
                    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                        Task { @MainActor in
                            chat.messages.append(message)
                            chat.updatedAt = Date()

                            do {
                                try await self.saveChat(chat)
                                continuation.resume()
                            } catch {
                                continuation.resume(throwing: error)
                            }
                        }
                    }

                    // Get the provider information
                    let providerString = chat.providerIdentifier
                    guard let _ = AIProvider(rawValue: providerString) else {
                        throw APIError.invalidProvider
                    }

                    // Nota: Aquí podrías usar el provider para configurar la stream response si fuera necesario

                    // Prepare response message
                    let assistantMessage = Message(role: .assistant, content: "")

                    // Add message and save chat
                    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                        Task { @MainActor in
                            chat.messages.append(assistantMessage)

                            do {
                                try await self.saveChat(chat)
                                continuation.resume()
                            } catch {
                                continuation.resume(throwing: error)
                            }
                        }
                    }

                    // For demonstration, we'll create a simple response
                    let response = "I'm a functional AI assistant responding in a stream. I received your message: \"\(message.content)\" and I'm here to help with any questions you have about using AI models or their integrations."

                    // Stream the response character by character
                    let responseChars = Array(response)
                    var localResponse = ""

                    for i in 0..<responseChars.count {
                        // Crear la cadena local para este punto de la iteración
                        localResponse += String(responseChars[i])

                        // Crear el fragmento para enviar al stream
                        let chunk = MessageChunk(
                            id: UUID(),
                            content: String(responseChars[i]),
                            isComplete: i == responseChars.count - 1
                        )
                        continuation.yield(chunk)

                        // Capturar una copia local de la respuesta para evitar la mutación después de la captura
                        let currentResponse = localResponse

                        // Update the message content as we go
                        await Task { @MainActor in
                            assistantMessage.content = currentResponse
                        }.value

                        // If this is the last character, save the chat
                        if i == responseChars.count - 1 {
                            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                                Task { @MainActor in
                                    chat.updatedAt = Date()

                                    do {
                                        try await self.saveChat(chat)
                                        continuation.resume()
                                    } catch {
                                        continuation.resume(throwing: error)
                                    }
                                }
                            }
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