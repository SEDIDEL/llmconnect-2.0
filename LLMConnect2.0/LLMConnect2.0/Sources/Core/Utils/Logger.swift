//
//  Logger.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import Foundation
import OSLog

// Create custom subsystems for the app
extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.llmconnect"
    
    static let app = Logger(subsystem: subsystem, category: "app")
    static let network = Logger(subsystem: subsystem, category: "network")
    static let database = Logger(subsystem: subsystem, category: "database")
    static let ui = Logger(subsystem: subsystem, category: "ui")
    static let aiService = Logger(subsystem: subsystem, category: "aiService")
    static let subscription = Logger(subsystem: subsystem, category: "subscription")
    static let security = Logger(subsystem: subsystem, category: "security")
}

enum LogLevel {
    case debug
    case info
    case notice
    case warning
    case error
    case critical
}

class AppLogger {
    static let shared = AppLogger()
    
    private init() {}
    
    func log(level: LogLevel, message: String, category: Logger = .app, file: String = #file, function: String = #function, line: Int = #line) {
        let fileURL = URL(fileURLWithPath: file)
        let fileName = fileURL.lastPathComponent
        let metadata = "\(fileName):\(line) - \(function)"
        
        switch level {
        case .debug:
            category.debug("[\(metadata)] \(message)")
        case .info:
            category.info("[\(metadata)] \(message)")
        case .notice:
            category.notice("[\(metadata)] \(message)")
        case .warning:
            category.warning("[\(metadata)] \(message)")
        case .error:
            category.error("[\(metadata)] \(message)")
        case .critical:
            category.critical("[\(metadata)] \(message)")
        }
    }
    
    func debug(_ message: String, category: Logger = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .debug, message: message, category: category, file: file, function: function, line: line)
    }
    
    func info(_ message: String, category: Logger = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .info, message: message, category: category, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, category: Logger = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .warning, message: message, category: category, file: file, function: function, line: line)
    }
    
    func error(_ message: String, category: Logger = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .error, message: message, category: category, file: file, function: function, line: line)
    }
    
    func critical(_ message: String, category: Logger = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .critical, message: message, category: category, file: file, function: function, line: line)
    }
    
    func logNetworkRequest(url: URL, method: String, statusCode: Int? = nil) {
        let message = "Request: \(method) \(url.absoluteString) \(statusCode != nil ? "Status: \(statusCode!)" : "")"
        info(message, category: .network)
    }
    
    func logNetworkError(error: Error, url: URL? = nil) {
        let urlString = url?.absoluteString ?? "unknown URL"
        self.error("Network Error: \(error.localizedDescription) - URL: \(urlString)", category: .network)
    }
}