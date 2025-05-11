//
//  AIProviderService.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import Foundation

struct AIModelInfo: Identifiable, Equatable {
    let id: String
    let name: String
    let contextSize: Int
    let capabilities: [String]
    
    static func == (lhs: AIModelInfo, rhs: AIModelInfo) -> Bool {
        return lhs.id == rhs.id
    }
}

protocol AIProviderServiceProtocol {
    func fetchAvailableModels(provider: AIProvider, apiKey: String) async throws -> [AIModelInfo]
    
    func defaultModels(for provider: AIProvider) -> [AIModelInfo]
}

class AIProviderService: AIProviderServiceProtocol {
    private let apiClient: APIClient
    
    init(apiClient: APIClient = APIClient(baseURL: URL(string: "https://api.openai.com/v1")!)) {
        self.apiClient = apiClient
    }
    
    func fetchAvailableModels(provider: AIProvider, apiKey: String) async throws -> [AIModelInfo] {
        guard !apiKey.isEmpty else {
            // If API key is empty, return default models
            return defaultModels(for: provider)
        }
        
        switch provider {
        case .openAI:
            return try await fetchOpenAIModels(apiKey: apiKey)
        case .anthropic:
            return try await fetchAnthropicModels(apiKey: apiKey)
        case .groq:
            return try await fetchGroqModels(apiKey: apiKey)
        case .perplexity:
            return try await fetchPerplexityModels(apiKey: apiKey)
        case .deepSeek:
            // Implementación para DeepSeek se añadirá más adelante
            return defaultModels(for: provider)
        case .openRouter:
            // Implementación para OpenRouter se añadirá más adelante
            return defaultModels(for: provider)
        case .custom:
            // Los modelos personalizados se manejan de manera diferente
            return []
        }
    }
    
    private func fetchOpenAIModels(apiKey: String) async throws -> [AIModelInfo] {
        // Si en algún momento hubiera un problema con la API, devolvemos los modelos por defecto
        do {
            let url = URL(string: "https://api.openai.com/v1/models")!
            var request = URLRequest(url: url)
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                // Si hay un error, devolvemos los modelos por defecto
                return defaultModels(for: .openAI)
            }
            
            // Decodificar la respuesta
            struct OpenAIModelsResponse: Decodable {
                let data: [OpenAIModel]
                
                struct OpenAIModel: Decodable {
                    let id: String
                }
            }
            
            let modelsResponse = try JSONDecoder().decode(OpenAIModelsResponse.self, from: data)
            
            // Filtrar solo los modelos que nos interesan (GPT)
            let gptModels = modelsResponse.data
                .filter { model in 
                    model.id.contains("gpt") && !model.id.contains("instruct") && !model.id.contains("-ft-")
                }
                .map { model in
                    // Mapear la información del modelo según su ID
                    mapOpenAIModelInfo(modelId: model.id)
                }
            
            return gptModels
        } catch {
            // En caso de error, devolvemos los modelos por defecto
            return defaultModels(for: .openAI)
        }
    }
    
    private func mapOpenAIModelInfo(modelId: String) -> AIModelInfo {
        // Mapear información del modelo según su ID
        if modelId.contains("gpt-4-turbo") {
            return AIModelInfo(
                id: modelId,
                name: "GPT-4 Turbo",
                contextSize: 128000,
                capabilities: ["Texto", "Análisis", "Razonamiento"]
            )
        } else if modelId.contains("gpt-4o") {
            return AIModelInfo(
                id: modelId,
                name: "GPT-4o",
                contextSize: 128000,
                capabilities: ["Texto", "Visión", "Audio"]
            )
        } else if modelId.contains("gpt-4") {
            return AIModelInfo(
                id: modelId,
                name: "GPT-4",
                contextSize: 8192,
                capabilities: ["Texto", "Análisis", "Razonamiento"]
            )
        } else if modelId.contains("gpt-3.5-turbo") {
            return AIModelInfo(
                id: modelId,
                name: "GPT-3.5 Turbo",
                contextSize: 16384,
                capabilities: ["Texto", "Análisis"]
            )
        } else {
            // Modelo desconocido, ponemos valores por defecto
            return AIModelInfo(
                id: modelId,
                name: modelId,
                contextSize: 4096,
                capabilities: ["Texto"]
            )
        }
    }
    
    private func fetchAnthropicModels(apiKey: String) async throws -> [AIModelInfo] {
        do {
            let url = URL(string: "https://api.anthropic.com/v1/models")!
            var request = URLRequest(url: url)
            request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
            request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return defaultModels(for: .anthropic)
            }
            
            // Decodificar la respuesta
            struct AnthropicModelsResponse: Decodable {
                let data: [AnthropicModel]
                
                struct AnthropicModel: Decodable {
                    let id: String
                    let context_window: Int?
                }
            }
            
            let modelsResponse = try JSONDecoder().decode(AnthropicModelsResponse.self, from: data)
            
            // Mapear los modelos
            return modelsResponse.data.map { model in
                AIModelInfo(
                    id: model.id,
                    name: formatAnthropicModelName(model.id),
                    contextSize: model.context_window ?? 200000,
                    capabilities: getAnthropicCapabilities(model.id)
                )
            }
        } catch {
            return defaultModels(for: .anthropic)
        }
    }
    
    private func formatAnthropicModelName(_ modelId: String) -> String {
        if modelId.contains("claude-3-7-sonnet") {
            return "Claude 3.7 Sonnet"
        } else if modelId.contains("claude-3-5-sonnet") {
            return "Claude 3.5 Sonnet"
        } else if modelId.contains("claude-3-opus") {
            return "Claude 3 Opus"
        } else if modelId.contains("claude-3-sonnet") {
            return "Claude 3 Sonnet"
        } else if modelId.contains("claude-3-haiku") {
            return "Claude 3 Haiku"
        } else if modelId.contains("claude-2") {
            return "Claude 2"
        } else {
            return modelId
        }
    }
    
    private func getAnthropicCapabilities(_ modelId: String) -> [String] {
        if modelId.contains("opus") {
            return ["Texto", "Visión", "Análisis", "Razonamiento", "Audio"]
        } else if modelId.contains("sonnet") {
            return ["Texto", "Visión", "Análisis", "Razonamiento"]
        } else if modelId.contains("haiku") {
            return ["Texto", "Visión", "Análisis"]
        } else {
            return ["Texto", "Análisis"]
        }
    }
    
    private func fetchGroqModels(apiKey: String) async throws -> [AIModelInfo] {
        do {
            let url = URL(string: "https://api.groq.com/openai/v1/models")!
            var request = URLRequest(url: url)
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return defaultModels(for: .groq)
            }
            
            // Decodificar la respuesta
            struct GroqModelsResponse: Decodable {
                let data: [GroqModel]
                
                struct GroqModel: Decodable {
                    let id: String
                }
            }
            
            let modelsResponse = try JSONDecoder().decode(GroqModelsResponse.self, from: data)
            
            // Mapear los modelos
            return modelsResponse.data.map { model in
                mapGroqModelInfo(modelId: model.id)
            }
        } catch {
            return defaultModels(for: .groq)
        }
    }
    
    private func mapGroqModelInfo(modelId: String) -> AIModelInfo {
        if modelId.contains("llama3-8b") {
            return AIModelInfo(
                id: modelId,
                name: "Llama-3 8B",
                contextSize: 8192,
                capabilities: ["Texto", "Análisis"]
            )
        } else if modelId.contains("llama3-70b") {
            return AIModelInfo(
                id: modelId,
                name: "Llama-3 70B",
                contextSize: 8192,
                capabilities: ["Texto", "Análisis", "Razonamiento"]
            )
        } else if modelId.contains("mixtral-8x7b") {
            return AIModelInfo(
                id: modelId,
                name: "Mixtral 8x7B",
                contextSize: 32768,
                capabilities: ["Texto", "Análisis"]
            )
        } else if modelId.contains("gemma-7b") {
            return AIModelInfo(
                id: modelId,
                name: "Gemma 7B",
                contextSize: 8192,
                capabilities: ["Texto", "Análisis"]
            )
        } else {
            return AIModelInfo(
                id: modelId,
                name: modelId,
                contextSize: 8192,
                capabilities: ["Texto"]
            )
        }
    }
    
    private func fetchPerplexityModels(apiKey: String) async throws -> [AIModelInfo] {
        // Perplexity no tiene un endpoint para listar modelos, así que devolvemos los por defecto
        return defaultModels(for: .perplexity)
    }
    
    func defaultModels(for provider: AIProvider) -> [AIModelInfo] {
        switch provider {
        case .openAI:
            return [
                AIModelInfo(
                    id: "gpt-4o",
                    name: "GPT-4o",
                    contextSize: 128000,
                    capabilities: ["Texto", "Visión", "Audio"]
                ),
                AIModelInfo(
                    id: "gpt-4-turbo",
                    name: "GPT-4 Turbo",
                    contextSize: 128000,
                    capabilities: ["Texto", "Análisis", "Razonamiento"]
                ),
                AIModelInfo(
                    id: "gpt-3.5-turbo",
                    name: "GPT-3.5 Turbo",
                    contextSize: 16384,
                    capabilities: ["Texto", "Análisis"]
                )
            ]
        case .anthropic:
            return [
                AIModelInfo(
                    id: "claude-3-opus-20240229",
                    name: "Claude 3 Opus",
                    contextSize: 200000,
                    capabilities: ["Texto", "Visión", "Análisis", "Razonamiento"]
                ),
                AIModelInfo(
                    id: "claude-3-sonnet-20240229",
                    name: "Claude 3 Sonnet",
                    contextSize: 200000,
                    capabilities: ["Texto", "Visión", "Análisis", "Razonamiento"]
                ),
                AIModelInfo(
                    id: "claude-3-haiku-20240307",
                    name: "Claude 3 Haiku",
                    contextSize: 200000,
                    capabilities: ["Texto", "Visión", "Análisis"]
                )
            ]
        case .groq:
            return [
                AIModelInfo(
                    id: "llama3-70b-8192",
                    name: "Llama-3 70B",
                    contextSize: 8192,
                    capabilities: ["Texto", "Análisis", "Razonamiento"]
                ),
                AIModelInfo(
                    id: "llama3-8b-8192",
                    name: "Llama-3 8B",
                    contextSize: 8192,
                    capabilities: ["Texto", "Análisis"]
                ),
                AIModelInfo(
                    id: "mixtral-8x7b-32768",
                    name: "Mixtral 8x7B",
                    contextSize: 32768,
                    capabilities: ["Texto", "Análisis"]
                )
            ]
        case .perplexity:
            return [
                AIModelInfo(
                    id: "sonar-pro-online",
                    name: "Sonar Pro",
                    contextSize: 12000,
                    capabilities: ["Texto", "Web", "Análisis"]
                ),
                AIModelInfo(
                    id: "sonar-medium-online",
                    name: "Sonar Medium",
                    contextSize: 12000,
                    capabilities: ["Texto", "Web", "Análisis"]
                ),
                AIModelInfo(
                    id: "sonar-small-online",
                    name: "Sonar Small",
                    contextSize: 12000,
                    capabilities: ["Texto", "Web"]
                )
            ]
        case .deepSeek:
            return [
                AIModelInfo(
                    id: "deepseek-chat",
                    name: "DeepSeek Chat",
                    contextSize: 32768,
                    capabilities: ["Texto", "Análisis"]
                ),
                AIModelInfo(
                    id: "deepseek-coder",
                    name: "DeepSeek Coder",
                    contextSize: 32768,
                    capabilities: ["Texto", "Código", "Análisis"]
                )
            ]
        case .openRouter:
            return [
                AIModelInfo(
                    id: "openai/gpt-4",
                    name: "GPT-4 (OpenAI)",
                    contextSize: 8192,
                    capabilities: ["Texto", "Análisis", "Razonamiento"]
                ),
                AIModelInfo(
                    id: "anthropic/claude-3-opus",
                    name: "Claude 3 Opus (Anthropic)",
                    contextSize: 200000,
                    capabilities: ["Texto", "Visión", "Análisis", "Razonamiento"]
                ),
                AIModelInfo(
                    id: "google/gemini-pro",
                    name: "Gemini Pro (Google)",
                    contextSize: 32768,
                    capabilities: ["Texto", "Análisis", "Razonamiento"]
                )
            ]
        case .custom:
            return []
        }
    }
}