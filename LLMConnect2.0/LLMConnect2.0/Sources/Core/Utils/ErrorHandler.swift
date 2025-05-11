//
//  ErrorHandler.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import Foundation
import OSLog

enum AppError: Error {
    case network(NetworkError)
    case database(DatabaseError)
    case validation(ValidationError)
    case authentication(AuthenticationError)
    case subscription(SubscriptionError)
    case unknown(Error)
    
    var localizedDescription: String {
        switch self {
        case .network(let error):
            return "Network Error: \(error.localizedDescription)"
        case .database(let error):
            return "Database Error: \(error.localizedDescription)"
        case .validation(let error):
            return "Validation Error: \(error.localizedDescription)"
        case .authentication(let error):
            return "Authentication Error: \(error.localizedDescription)"
        case .subscription(let error):
            return "Subscription Error: \(error.localizedDescription)"
        case .unknown(let error):
            return "Unknown Error: \(error.localizedDescription)"
        }
    }
    
    var userFriendlyDescription: String {
        switch self {
        case .network(let error):
            return error.userFriendlyDescription
        case .database(let error):
            return error.userFriendlyDescription
        case .validation(let error):
            return error.userFriendlyDescription
        case .authentication(let error):
            return error.userFriendlyDescription
        case .subscription(let error):
            return error.userFriendlyDescription
        case .unknown:
            return "An unexpected error occurred. Please try again later."
        }
    }
    
    var isRecoverable: Bool {
        switch self {
        case .network(let error):
            return error.isRecoverable
        case .database(let error):
            return error.isRecoverable
        case .validation(let error):
            return error.isRecoverable
        case .authentication(let error):
            return error.isRecoverable
        case .subscription(let error):
            return error.isRecoverable
        case .unknown:
            return false
        }
    }
    
    var logLevel: LogLevel {
        switch self {
        case .network(let error):
            return error.logLevel
        case .database(let error):
            return error.logLevel
        case .validation(let error):
            return error.logLevel
        case .authentication(let error):
            return error.logLevel
        case .subscription(let error):
            return error.logLevel
        case .unknown:
            return .error
        }
    }
}

enum NetworkError: Error {
    case invalidURL
    case connectionFailed
    case timeout
    case serverError(statusCode: Int, message: String?)
    case decodingFailed
    case noData
    case rateLimited
    case unauthorized
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL."
        case .connectionFailed:
            return "Failed to connect to the server."
        case .timeout:
            return "Request timed out."
        case .serverError(let statusCode, let message):
            return "Server error (\(statusCode)): \(message ?? "No additional information")"
        case .decodingFailed:
            return "Failed to decode server response."
        case .noData:
            return "No data received from server."
        case .rateLimited:
            return "Rate limit exceeded."
        case .unauthorized:
            return "Unauthorized access."
        }
    }
    
    var userFriendlyDescription: String {
        switch self {
        case .invalidURL:
            return "There's an issue with the request. Please try again later."
        case .connectionFailed:
            return "Unable to connect to the server. Please check your internet connection."
        case .timeout:
            return "The server is taking too long to respond. Please try again later."
        case .serverError:
            return "The server encountered an error. Please try again later."
        case .decodingFailed:
            return "There was an issue processing the server response."
        case .noData:
            return "No data received from the server."
        case .rateLimited:
            return "You've reached the rate limit. Please try again in a few moments."
        case .unauthorized:
            return "Your API key appears to be invalid. Please check your settings."
        }
    }
    
    var isRecoverable: Bool {
        switch self {
        case .invalidURL, .decodingFailed:
            return false
        case .connectionFailed, .timeout, .serverError, .noData, .rateLimited, .unauthorized:
            return true
        }
    }
    
    var logLevel: LogLevel {
        switch self {
        case .invalidURL, .decodingFailed:
            return .error
        case .connectionFailed, .timeout, .noData:
            return .warning
        case .serverError:
            return .error
        case .rateLimited:
            return .warning
        case .unauthorized:
            return .error
        }
    }
}

enum DatabaseError: Error {
    case invalidEntity
    case readFailed
    case writeFailed
    case deleteFailed
    case migrationFailed
    case corruptData
    
    var localizedDescription: String {
        switch self {
        case .invalidEntity:
            return "Invalid entity."
        case .readFailed:
            return "Failed to read data from database."
        case .writeFailed:
            return "Failed to write data to database."
        case .deleteFailed:
            return "Failed to delete data from database."
        case .migrationFailed:
            return "Database migration failed."
        case .corruptData:
            return "Database contains corrupt data."
        }
    }
    
    var userFriendlyDescription: String {
        switch self {
        case .invalidEntity, .readFailed, .writeFailed, .deleteFailed, .migrationFailed:
            return "There was an issue with the app's storage. Please restart the app."
        case .corruptData:
            return "Some data appears to be corrupted. Please contact support."
        }
    }
    
    var isRecoverable: Bool {
        switch self {
        case .invalidEntity, .readFailed, .writeFailed, .deleteFailed:
            return true
        case .migrationFailed, .corruptData:
            return false
        }
    }
    
    var logLevel: LogLevel {
        switch self {
        case .invalidEntity, .readFailed, .writeFailed, .deleteFailed:
            return .error
        case .migrationFailed, .corruptData:
            return .critical
        }
    }
}

enum ValidationError: Error {
    case invalidInput(field: String)
    case missingRequiredField(field: String)
    case invalidFormat(field: String)
    
    var localizedDescription: String {
        switch self {
        case .invalidInput(let field):
            return "Invalid input for \(field)."
        case .missingRequiredField(let field):
            return "Missing required field: \(field)."
        case .invalidFormat(let field):
            return "Invalid format for \(field)."
        }
    }
    
    var userFriendlyDescription: String {
        switch self {
        case .invalidInput(let field):
            return "The input for \(field) is invalid."
        case .missingRequiredField(let field):
            return "Please provide a value for \(field)."
        case .invalidFormat(let field):
            return "The format for \(field) is incorrect."
        }
    }
    
    var isRecoverable: Bool {
        return true
    }
    
    var logLevel: LogLevel {
        return .warning
    }
}

enum AuthenticationError: Error {
    case invalidAPIKey
    case expiredAPIKey
    case missingAPIKey
    
    var localizedDescription: String {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key."
        case .expiredAPIKey:
            return "Expired API key."
        case .missingAPIKey:
            return "Missing API key."
        }
    }
    
    var userFriendlyDescription: String {
        switch self {
        case .invalidAPIKey:
            return "Your API key appears to be invalid. Please check it in settings."
        case .expiredAPIKey:
            return "Your API key has expired. Please update it in settings."
        case .missingAPIKey:
            return "Please add your API key in settings."
        }
    }
    
    var isRecoverable: Bool {
        return true
    }
    
    var logLevel: LogLevel {
        return .error
    }
}

enum SubscriptionError: Error {
    case purchaseFailed
    case productNotFound
    case receiptValidationFailed
    case noActiveSubscription
    
    var localizedDescription: String {
        switch self {
        case .purchaseFailed:
            return "Purchase failed."
        case .productNotFound:
            return "Product not found."
        case .receiptValidationFailed:
            return "Receipt validation failed."
        case .noActiveSubscription:
            return "No active subscription."
        }
    }
    
    var userFriendlyDescription: String {
        switch self {
        case .purchaseFailed:
            return "Purchase could not be completed. Please try again later."
        case .productNotFound:
            return "This product is currently unavailable."
        case .receiptValidationFailed:
            return "We couldn't verify your purchase. Please contact support."
        case .noActiveSubscription:
            return "You don't have an active subscription."
        }
    }
    
    var isRecoverable: Bool {
        switch self {
        case .purchaseFailed, .productNotFound, .noActiveSubscription:
            return true
        case .receiptValidationFailed:
            return false
        }
    }
    
    var logLevel: LogLevel {
        return .error
    }
}

class ErrorHandler {
    static let shared = ErrorHandler()
    
    private init() {}
    
    func handle(error: Error, file: String = #file, function: String = #function, line: Int = #line) {
        // Convert to AppError if needed
        let appError: AppError
        if let error = error as? AppError {
            appError = error
        } else if let error = error as? NetworkError {
            appError = .network(error)
        } else if let error = error as? DatabaseError {
            appError = .database(error)
        } else if let error = error as? ValidationError {
            appError = .validation(error)
        } else if let error = error as? AuthenticationError {
            appError = .authentication(error)
        } else if let error = error as? SubscriptionError {
            appError = .subscription(error)
        } else {
            appError = .unknown(error)
        }
        
        // Log the error
        let fileURL = URL(fileURLWithPath: file)
        let fileName = fileURL.lastPathComponent
        let metadata = "\(fileName):\(line) - \(function)"
        
        let logMessage = "[\(metadata)] \(appError.localizedDescription)"
        
        switch appError.logLevel {
        case .debug:
            Logger.app.debug("\(logMessage)")
        case .info:
            Logger.app.info("\(logMessage)")
        case .notice:
            Logger.app.notice("\(logMessage)")
        case .warning:
            Logger.app.warning("\(logMessage)")
        case .error:
            Logger.app.error("\(logMessage)")
        case .critical:
            Logger.app.critical("\(logMessage)")
        }
        
        // Additional handling like crash reporting could go here
    }
    
    func getUserFriendlyMessage(from error: Error) -> String {
        // Convert to AppError if needed
        let appError: AppError
        if let error = error as? AppError {
            appError = error
        } else if let error = error as? NetworkError {
            appError = .network(error)
        } else if let error = error as? DatabaseError {
            appError = .database(error)
        } else if let error = error as? ValidationError {
            appError = .validation(error)
        } else if let error = error as? AuthenticationError {
            appError = .authentication(error)
        } else if let error = error as? SubscriptionError {
            appError = .subscription(error)
        } else {
            appError = .unknown(error)
        }
        
        return appError.userFriendlyDescription
    }
}