//
//  AppCoordinator.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import SwiftUI
import Combine

@MainActor
class AppCoordinator: ObservableObject {
    @Published var selectedTab: Tab = .chat

    // ViewModels
    private let chatListViewModel = ChatListViewModel()
    private let botGalleryViewModel = BotGalleryViewModel()
    private let memoryViewModel = MemoryViewModel()
    private let settingsViewModel = SettingsViewModel()

    private let serviceLocator = ServiceLocator.shared
    private var cancellables = Set<AnyCancellable>()
    
    enum Tab {
        case chat
        case bots
        case memory
        case settings
    }
    
    init() {
        // Dependencies are now registered in DependencyInjection.swift
    }
    
    func rootView() -> some View {
        TabView(selection: Binding<Tab>(
            get: { self.selectedTab },
            set: { self.selectedTab = $0 }
        )) {
            NavigationStack {
                ChatListView(viewModel: self.chatListViewModel)
            }
            .tabItem {
                Label("Chats", systemImage: "bubble.left.and.bubble.right")
            }
            .tag(Tab.chat)

            NavigationStack {
                BotGalleryView(viewModel: self.botGalleryViewModel)
            }
            .tabItem {
                Label("Bots", systemImage: "person.bust")
            }
            .tag(Tab.bots)

            NavigationStack {
                MemoryView(viewModel: self.memoryViewModel)
            }
            .tabItem {
                Label("Memory", systemImage: "brain")
            }
            .tag(Tab.memory)

            NavigationStack {
                SettingsView(viewModel: self.settingsViewModel)
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(Tab.settings)
        }
    }
}