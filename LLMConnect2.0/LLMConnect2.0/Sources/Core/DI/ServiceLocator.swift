//
//  ServiceLocator.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import Foundation

final class ServiceLocator {
    static let shared = ServiceLocator()
    
    private init() {}
    
    private var services: [String: Any] = [:]
    
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        services[String(describing: type)] = factory
    }
    
    func resolve<T>() -> T {
        let key = String(describing: T.self)
        guard let factory = services[key] as? () -> T else {
            fatalError("Service of type \(T.self) not registered")
        }
        
        return factory()
    }
}

// Eliminamos el property wrapper @Inject que causa problemas
// y simplemente usamos ServiceLocator directamente en las clases