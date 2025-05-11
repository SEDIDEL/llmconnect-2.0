//
//  APIClient.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

struct Endpoint {
    let path: String
    let method: HTTPMethod
    let headers: [String: String]?
    let queryItems: [URLQueryItem]?
    let body: Data?
    
    init(
        path: String,
        method: HTTPMethod = .get,
        headers: [String: String]? = nil,
        queryItems: [URLQueryItem]? = nil,
        body: Data? = nil
    ) {
        self.path = path
        self.method = method
        self.headers = headers
        self.queryItems = queryItems
        self.body = body
    }
    
    static func chat(provider: AIProvider, messages: [Message]) -> Endpoint {
        // Implementation would depend on the provider
        switch provider {
        case .openAI:
            return createOpenAIChatEndpoint(messages: messages)
        case .anthropic:
            return createAnthropicChatEndpoint(messages: messages)
        default:
            // Default implementation for other providers
            return createDefaultChatEndpoint(provider: provider, messages: messages)
        }
    }
    
    private static func createOpenAIChatEndpoint(messages: [Message]) -> Endpoint {
        // OpenAI-specific implementation
        let jsonMessages = messages.map { message in
            return [
                "role": message.role.rawValue,
                "content": message.content
            ]
        }
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": jsonMessages,
            "stream": false
        ]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: requestBody)
        
        return Endpoint(
            path: "/chat/completions",
            method: .post,
            headers: [
                "Content-Type": "application/json",
                "Authorization": "Bearer \(KeychainManager.shared.retrieveAPIKey(for: AIProvider.openAI.rawValue) ?? "")"
            ],
            body: jsonData
        )
    }
    
    private static func createAnthropicChatEndpoint(messages: [Message]) -> Endpoint {
        // Anthropic-specific implementation
        // Similar to OpenAI but with Anthropic's API requirements
        let jsonData = Data() // Placeholder
        
        return Endpoint(
            path: "/messages",
            method: .post,
            headers: [
                "Content-Type": "application/json",
                "X-API-Key": KeychainManager.shared.retrieveAPIKey(for: AIProvider.anthropic.rawValue) ?? "",
                "anthropic-version": "2023-06-01"
            ],
            body: jsonData
        )
    }
    
    private static func createDefaultChatEndpoint(provider: AIProvider, messages: [Message]) -> Endpoint {
        // Generic implementation
        let jsonData = Data() // Placeholder
        
        return Endpoint(
            path: "/chat",
            method: .post,
            headers: [
                "Content-Type": "application/json",
                "Authorization": "Bearer \(KeychainManager.shared.retrieveAPIKey(for: provider.rawValue) ?? "")"
            ],
            body: jsonData
        )
    }
}

protocol APIClientProtocol {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    func requestStream<T: Decodable>(_ endpoint: Endpoint) -> AsyncThrowingStream<T, Error>
}

class APIClient: APIClientProtocol {
    private let session: URLSession
    private let baseURL: URL
    
    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        guard var urlComponents = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: true) else {
            throw APIError.invalidURL
        }
        
        if let queryItems = endpoint.queryItems {
            urlComponents.queryItems = queryItems
        }
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        if let headers = endpoint.headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        request.httpBody = endpoint.body
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    func requestStream<T: Decodable>(_ endpoint: Endpoint) -> AsyncThrowingStream<T, Error> {
        return AsyncThrowingStream { continuation in
            // Implementation of streaming would depend on the provider
            // This is a placeholder implementation
            Task {
                continuation.finish()
            }
        }
    }
}

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, data: Data)
    case decodingError(Error)
}