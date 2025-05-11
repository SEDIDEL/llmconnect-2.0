//
//  ChatListView.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import SwiftUI

struct ChatListView: View {
    @StateObject var viewModel: ChatListViewModel
    @State private var showingNewChatSheet = false
    @State private var showingNewFolderSheet = false
    @State private var newFolderName = ""
    @State private var newFolderColor = "blue"
    @State private var selectedChat: Chat? = nil
    @State private var navigateToChat = false

    private let folderColors = ["blue", "green", "orange", "purple", "red", "teal", "yellow", "pink"]
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .padding()
            } else if viewModel.chats.isEmpty {
                emptyStateView
            } else {
                chatListContent
            }
        }
        .background(
            NavigationLink(
                destination: selectedChat.map { ChatView(viewModel: ChatViewModel(chat: $0)) },
                isActive: $navigateToChat,
                label: { EmptyView() }
            )
        )
        .navigationTitle("Chats")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    showingNewFolderSheet = true
                }) {
                    Label("New Folder", systemImage: "folder.badge.plus")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingNewChatSheet = true
                }) {
                    Label("New Chat", systemImage: "square.and.pencil")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        viewModel.toggleShowArchived()
                    }) {
                        Label(
                            viewModel.showingArchived ? "Show Active Chats" : "Show Archived Chats",
                            systemImage: viewModel.showingArchived ? "tray" : "archivebox"
                        )
                    }
                    
                    Divider()
                    
                    Menu("Sort By") {
                        Button("Latest") { }
                        Button("Oldest") { }
                        Button("Alphabetical") { }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search chats")
        .onChange(of: viewModel.searchText) { _, newValue in
            if newValue.isEmpty {
                viewModel.loadChats()
            } else {
                viewModel.searchChats()
            }
        }
        .sheet(isPresented: $showingNewChatSheet) {
            NewChatView { provider, model in
                let newChat = viewModel.createNewChat(provider: provider, model: model)
                selectedChat = newChat
                showingNewChatSheet = false

                // Usar DispatchQueue para asegurar que la navegación ocurra después de que se cierre la hoja
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    navigateToChat = true
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingNewFolderSheet) {
            newFolderView
                .presentationDetents([.medium])
        }
        .alert(
            "Error",
            isPresented: Binding<Bool>(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            ),
            presenting: viewModel.errorMessage
        ) { message in
            Button("OK", role: .cancel) { }
        } message: { message in
            Text(message)
        }
    }
    
    private var chatListContent: some View {
        List {
            // Sección de carpetas
            if !viewModel.folders.isEmpty {
                Section(header: Text("Folders")) {
                    ForEach(viewModel.folders) { folder in
                        Button(action: {
                            viewModel.selectFolder(folder)
                        }) {
                            HStack {
                                Image(systemName: "folder")
                                    .foregroundColor(DesignTokens.Colors.Folder.color(from: folder.color))
                                Text(folder.name)
                                Spacer()
                                Text("\(folder.chats?.count ?? 0)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Button("All Chats") {
                        viewModel.selectFolder(nil)
                    }
                }
            }
            
            // Sección de chats fijados
            let pinnedChats = viewModel.chats.filter({ $0.isPinned })
            if !pinnedChats.isEmpty {
                Section(header: Text("Pinned")) {
                    ForEach(pinnedChats) { chat in
                        ChatRow(chat: chat)
                            .swipeActions(edge: .leading) {
                                Button {
                                    viewModel.pinChat(chat)
                                } label: {
                                    Label("Unpin", systemImage: "pin.slash")
                                }
                                .tint(.blue)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.deleteChat(chat)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    viewModel.toggleArchiveChat(chat)
                                } label: {
                                    Label(
                                        chat.isArchived ? "Unarchive" : "Archive",
                                        systemImage: chat.isArchived ? "tray" : "archivebox"
                                    )
                                }
                                .tint(.orange)
                            }
                            .contextMenu {
                                Button {
                                    viewModel.pinChat(chat)
                                } label: {
                                    Label("Unpin", systemImage: "pin.slash")
                                }
                                
                                Menu("Move to") {
                                    ForEach(viewModel.folders) { folder in
                                        Button(folder.name) {
                                            viewModel.moveChat(chat, to: folder)
                                        }
                                    }
                                    
                                    Button("No Folder") {
                                        viewModel.moveChat(chat, to: nil)
                                    }
                                }
                                
                                Button {
                                    viewModel.toggleArchiveChat(chat)
                                } label: {
                                    Label(
                                        chat.isArchived ? "Unarchive" : "Archive",
                                        systemImage: chat.isArchived ? "tray" : "archivebox"
                                    )
                                }
                                
                                Divider()
                                
                                Button(role: .destructive) {
                                    viewModel.deleteChat(chat)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            
            // Sección de chats regulares
            Section(header: Text(viewModel.showingArchived ? "Archived" : "Chats")) {
                ForEach(viewModel.chats.filter { !$0.isPinned }) { chat in
                    ChatRow(chat: chat)
                        .swipeActions(edge: .leading) {
                            Button {
                                viewModel.pinChat(chat)
                            } label: {
                                Label("Pin", systemImage: "pin")
                            }
                            .tint(.blue)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.deleteChat(chat)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                viewModel.toggleArchiveChat(chat)
                            } label: {
                                Label(
                                    chat.isArchived ? "Unarchive" : "Archive",
                                    systemImage: chat.isArchived ? "tray" : "archivebox"
                                )
                            }
                            .tint(.orange)
                        }
                        .contextMenu {
                            Button {
                                viewModel.pinChat(chat)
                            } label: {
                                Label("Pin", systemImage: "pin")
                            }
                            
                            Menu("Move to") {
                                ForEach(viewModel.folders) { folder in
                                    Button(folder.name) {
                                        viewModel.moveChat(chat, to: folder)
                                    }
                                }
                                
                                Button("No Folder") {
                                    viewModel.moveChat(chat, to: nil)
                                }
                            }
                            
                            Button {
                                viewModel.toggleArchiveChat(chat)
                            } label: {
                                Label(
                                    chat.isArchived ? "Unarchive" : "Archive",
                                    systemImage: chat.isArchived ? "tray" : "archivebox"
                                )
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                viewModel.deleteChat(chat)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 72))
                .foregroundColor(.gray)
            
            Text(viewModel.showingArchived ? "No archived chats" : "No chats yet")
                .font(.title2)
                .bold()
            
            Text(viewModel.showingArchived ?
                 "Archived chats will appear here" :
                 "Start a new conversation by tapping the + button")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            if !viewModel.showingArchived {
                Button(action: {
                    showingNewChatSheet = true
                }) {
                    Text("New Chat")
                        .bold()
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.top, 8)
            }
        }
        .padding()
    }
    
    private var newFolderView: some View {
        NavigationView {
            Form {
                Section(header: Text("Folder Name")) {
                    TextField("Enter folder name", text: $newFolderName)
                }
                
                Section(header: Text("Color")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 10) {
                        ForEach(folderColors, id: \.self) { color in
                            Circle()
                                .fill(DesignTokens.Colors.Folder.color(from: color))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: newFolderColor == color ? 2 : 0)
                                        .padding(2)
                                )
                                .onTapGesture {
                                    newFolderColor = color
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("New Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingNewFolderSheet = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        if !newFolderName.isEmpty {
                            viewModel.createFolder(name: newFolderName, color: newFolderColor)
                            newFolderName = ""
                            newFolderColor = "blue"
                            showingNewFolderSheet = false
                        }
                    }
                    .disabled(newFolderName.isEmpty)
                }
            }
        }
    }
}

struct ChatRow: View {
    let chat: Chat
    
    var body: some View {
        NavigationLink(destination: ChatView(viewModel: ChatViewModel(chat: chat))) {
            HStack(spacing: 12) {
                // Avatar del proveedor de IA
                Image(AIProvider(rawValue: chat.providerIdentifier)?.iconName ?? "custom-icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(chat.title ?? "New Chat")
                        .font(.headline)
                    
                    Text(chat.messages.last?.content.prefix(80) ?? "No messages yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    // Fecha de último mensaje
                    if let lastMessageDate = chat.messages.last?.timestamp {
                        Text(timeAgo(from: lastMessageDate))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text(timeAgo(from: chat.createdAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Íconos de estado
                    HStack(spacing: 4) {
                        if chat.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        if chat.isArchived {
                            Image(systemName: "archivebox.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // Función para formatear la fecha como "tiempo atrás"
    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day, .weekOfMonth], from: date, to: now)
        
        if let minute = components.minute, minute < 60 {
            return minute == 0 ? "Just now" : "\(minute)m ago"
        } else if let hour = components.hour, hour < 24 {
            return "\(hour)h ago"
        } else if let day = components.day, day < 7 {
            return "\(day)d ago"
        } else if let week = components.weekOfMonth, week < 4 {
            return "\(week)w ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
}

struct NewChatView: View {
    @StateObject private var viewModel = NewChatViewModel()
    @Environment(\.dismiss) private var dismiss

    var onCreateChat: (AIProvider, String) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("AI Provider")) {
                    Picker("Provider", selection: $viewModel.selectedProvider) {
                        ForEach(AIProvider.allCases) { provider in
                            if provider != .custom {
                                Text(provider.displayName)
                                    .tag(provider)
                            }
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: viewModel.selectedProvider) { _, _ in
                        viewModel.providerChanged()
                    }
                }

                Section(header: Text("Model")) {
                    if viewModel.isLoadingModels {
                        HStack {
                            Spacer()
                            ProgressView()
                                .padding()
                            Spacer()
                        }
                    } else {
                        Picker("Model", selection: $viewModel.selectedModelId) {
                            ForEach(viewModel.availableModels) { model in
                                HStack {
                                    Text(model.name)
                                    Spacer()
                                    Text("\(model.contextSize/1000)k ctx")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .tag(model.id)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())

                        // Mostrar las capacidades del modelo seleccionado
                        if let selectedModel = viewModel.availableModels.first(where: { $0.id == viewModel.selectedModelId }) {
                            HStack {
                                Text("Capabilities:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(selectedModel.capabilities, id: \.self) { capability in
                                            Text(capability)
                                                .font(.caption)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.accentColor.opacity(0.2))
                                                .foregroundColor(.accentColor)
                                                .cornerRadius(4)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreateChat(viewModel.selectedProvider, viewModel.selectedModelId)
                        dismiss()
                    }
                }
            }
            .alert(isPresented: Binding<Bool>(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.errorMessage ?? ""),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

// Helper para mostrar alertas de error
struct ErrorAlert: Identifiable {
    let id = UUID()
    let message: String
}