//
//  ChatRepositoryProtocol.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import Foundation

struct MessageChunk: Sendable {
    let id: UUID
    let content: String
    let isComplete: Bool
}

protocol ChatRepositoryProtocol {
    func getChats() async throws -> [Chat]
    func getChat(id: UUID) async throws -> Chat
    func saveChat(_ chat: Chat) async throws
    func deleteChat(id: UUID) async throws
    func sendMessage(_ message: Message, in chatID: UUID) async throws -> Message
    func streamMessage(_ message: Message, in chatID: UUID) -> AsyncThrowingStream<MessageChunk, Error>
    func updateChatTitle(id: UUID, title: String) async throws
    func pinChat(id: UUID, isPinned: Bool) async throws
    func archiveChat(id: UUID, isArchived: Bool) async throws
    func moveChat(id: UUID, to folderID: UUID?) async throws
    func searchChats(query: String) async throws -> [Chat]
    func getFolders() async throws -> [Folder]
    func createFolder(_ folder: Folder) async throws
}