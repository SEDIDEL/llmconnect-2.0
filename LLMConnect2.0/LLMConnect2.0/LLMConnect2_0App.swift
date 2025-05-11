//
//  LLMConnect2_0App.swift
//  LLMConnect2.0
//
//  Created by Sebastian Diaz on 10/05/25.
//

import SwiftUI
import SwiftData

// Main app entry point
@main
struct LLMConnect2_0App: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            Chat.self,
            Message.self,
            Bot.self,
            Memory.self,
            Prompt.self,
            GeneratedImage.self,
            Folder.self,
            Citation.self,
            PromptCategory.self,
            KnowledgeSource.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @StateObject private var appCoordinator = AppCoordinator()

    // Registro sincrónico de las dependencias
    init() {
        // Esta inicialización debe hacerse en el hilo principal
        DependencyInjection.registerAllServices()
    }

    var body: some Scene {
        WindowGroup {
            appCoordinator.rootView()
                .onAppear {
                    // Configure SwiftDataManager with our container
                    SwiftDataManager.shared.configure(with: sharedModelContainer)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}