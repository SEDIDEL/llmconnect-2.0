//
//  LLMConnectApp.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import SwiftUI
import SwiftData

// Removido @main para evitar conflicto con LLMConnect2_0App.swift
struct LLMConnectApp: App {
    @StateObject private var appCoordinator = AppCoordinator()
    
    var body: some Scene {
        WindowGroup {
            appCoordinator.rootView()
        }
        .modelContainer(for: [
            Chat.self,
            Message.self,
            Bot.self,
            Memory.self,
            Prompt.self,
            GeneratedImage.self,
        ])
    }
}