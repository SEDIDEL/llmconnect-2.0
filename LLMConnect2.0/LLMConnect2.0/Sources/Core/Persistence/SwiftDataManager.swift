//
//  SwiftDataManager.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import Foundation
import SwiftData
import OSLog

@MainActor
class SwiftDataManager {
    static let shared = SwiftDataManager()
    
    private let logger = Logger.database
    private var context: ModelContext?
    
    private init() {}
    
    func configure(with modelContainer: ModelContainer) {
        context = ModelContext(modelContainer)
        logger.info("SwiftData manager configured with model container")
    }
    
    func save() async throws {
        guard let context = context else {
            logger.error("Attempted to save with nil context")
            throw DatabaseError.writeFailed
        }
        
        do {
            // Añadimos un await a Task.yield() para crear un punto de suspensión
            await Task.yield()
            try context.save()
            logger.debug("Context saved successfully")
        } catch {
            logger.error("Failed to save context: \(error.localizedDescription)")
            throw DatabaseError.writeFailed
        }
    }
    
    func fetch<T: PersistentModel>(_ modelType: T.Type, predicate: Predicate<T>? = nil, sortBy: [SortDescriptor<T>]? = nil) async throws -> [T] {
        guard let context = context else {
            logger.error("Attempted to fetch with nil context")
            throw DatabaseError.readFailed
        }
        
        do {
            var descriptor = FetchDescriptor<T>()
            
            if let predicate = predicate {
                descriptor.predicate = predicate
            }
            
            if let sortDescriptors = sortBy {
                descriptor.sortBy = sortDescriptors
            }
            
            // Añadimos un await a Task.yield() para crear un punto de suspensión
            await Task.yield()
            let results = try context.fetch(descriptor)
            logger.debug("Fetched \(results.count) items of type \(String(describing: modelType))")
            return results
        } catch {
            logger.error("Failed to fetch: \(error.localizedDescription)")
            throw DatabaseError.readFailed
        }
    }
    
    func fetchOne<T: PersistentModel>(_ modelType: T.Type, predicate: Predicate<T>) async throws -> T? {
        guard let context = context else {
            logger.error("Attempted to fetch with nil context")
            throw DatabaseError.readFailed
        }
        
        do {
            var descriptor = FetchDescriptor<T>()
            descriptor.predicate = predicate
            descriptor.fetchLimit = 1
            
            // Añadimos un await a Task.yield() para crear un punto de suspensión
            await Task.yield()
            let results = try context.fetch(descriptor)
            logger.debug("Fetched \(results.isEmpty ? "no" : "one") item of type \(String(describing: modelType))")
            return results.first
        } catch {
            logger.error("Failed to fetch one: \(error.localizedDescription)")
            throw DatabaseError.readFailed
        }
    }
    
    func delete<T: PersistentModel>(_ object: T) async throws {
        guard let context = context else {
            logger.error("Attempted to delete with nil context")
            throw DatabaseError.deleteFailed
        }
        
        do {
            context.delete(object)
            // Añadimos un await a Task.yield() para crear un punto de suspensión
            await Task.yield()
            try context.save()
            logger.debug("Deleted object of type \(String(describing: type(of: object)))")
        } catch {
            logger.error("Failed to delete: \(error.localizedDescription)")
            throw DatabaseError.deleteFailed
        }
    }
    
    func deleteAll<T: PersistentModel>(_ modelType: T.Type) async throws {
        guard let context = context else {
            logger.error("Attempted to delete all with nil context")
            throw DatabaseError.deleteFailed
        }
        
        do {
            try context.delete(model: T.self, where: #Predicate { _ in true })
            // Añadimos un await a Task.yield() para crear un punto de suspensión
            await Task.yield()
            try context.save()
            logger.debug("Deleted all objects of type \(String(describing: modelType))")
        } catch {
            logger.error("Failed to delete all: \(error.localizedDescription)")
            throw DatabaseError.deleteFailed
        }
    }
    
    func count<T: PersistentModel>(_ modelType: T.Type, predicate: Predicate<T>? = nil) async throws -> Int {
        guard let context = context else {
            logger.error("Attempted to count with nil context")
            throw DatabaseError.readFailed
        }
        
        do {
            var descriptor = FetchDescriptor<T>()
            
            if let predicate = predicate {
                descriptor.predicate = predicate
            }
            
            // Añadimos un await a Task.yield() para crear un punto de suspensión
            await Task.yield()
            return try context.fetchCount(descriptor)
        } catch {
            logger.error("Failed to count: \(error.localizedDescription)")
            throw DatabaseError.readFailed
        }
    }
}