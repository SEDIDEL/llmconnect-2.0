//
//  BotRepositoryProtocol.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import Foundation

protocol BotRepositoryProtocol {
    func getBots() async throws -> [Bot]
    func getBot(id: UUID) async throws -> Bot
    func saveBot(_ bot: Bot) async throws
    func deleteBot(id: UUID) async throws
    func addKnowledgeSource(_ source: KnowledgeSource, to botID: UUID) async throws
    func removeKnowledgeSource(id: UUID, from botID: UUID) async throws
    func updateBotSystemPrompt(id: UUID, systemPrompt: String) async throws
    func searchBots(query: String) async throws -> [Bot]
}