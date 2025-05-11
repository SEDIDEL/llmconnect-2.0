//
//  SendMessageUseCase.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import Foundation

class SendMessageUseCase {
    private let chatRepository: ChatRepositoryProtocol
    
    init(chatRepository: ChatRepositoryProtocol) {
        self.chatRepository = chatRepository
    }
    
    func execute(message: Message, in chatID: UUID) async throws -> Message {
        return try await chatRepository.sendMessage(message, in: chatID)
    }
    
    func executeStream(message: Message, in chatID: UUID) -> AsyncThrowingStream<MessageChunk, Error> {
        return chatRepository.streamMessage(message, in: chatID)
    }
}