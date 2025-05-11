//
//  BotGalleryView.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import SwiftUI

struct BotGalleryView: View {
    @StateObject var viewModel: BotGalleryViewModel
    @State private var showingNewBotSheet = false
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .padding()
            } else if viewModel.bots.isEmpty {
                emptyStateView
            } else {
                botGalleryContent
            }
        }
        .navigationTitle("Bots")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingNewBotSheet = true
                }) {
                    Label("New Bot", systemImage: "plus.circle")
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search bots")
        .onChange(of: viewModel.searchText) { _, newValue in
            if newValue.isEmpty {
                viewModel.loadBots()
            } else {
                viewModel.searchBots()
            }
        }
        .sheet(isPresented: $showingNewBotSheet) {
            NewBotView { name, emoji, description, systemPrompt, provider, model in
                _ = viewModel.createBot(
                    name: name,
                    emoji: emoji,
                    description: description,
                    systemPrompt: systemPrompt,
                    provider: provider,
                    model: model
                )
                showingNewBotSheet = false
            }
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
    
    private var botGalleryContent: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                ForEach(viewModel.bots) { bot in
                    BotCard(bot: bot)
                        .contextMenu {
                            Button {
                                // Navegar a editar bot
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            
                            Button {
                                // Iniciar chat con este bot
                            } label: {
                                Label("Start Chat", systemImage: "bubble.right")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                viewModel.deleteBot(bot)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.bust")
                .font(.system(size: 72))
                .foregroundColor(.gray)
            
            Text("No bots yet")
                .font(.title2)
                .bold()
            
            Text("Create a custom bot by tapping the + button")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button(action: {
                showingNewBotSheet = true
            }) {
                Text("Create Bot")
                    .bold()
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.top, 8)
        }
        .padding()
    }
}

struct BotCard: View {
    let bot: Bot
    
    var body: some View {
        NavigationLink(destination: BotDetailView(bot: bot)) {
            VStack(spacing: 8) {
                // Emoji o avatar
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Text(bot.emoji)
                        .font(.system(size: 40))
                }
                .padding(.top, 8)
                
                // Nombre del bot
                Text(bot.name)
                    .font(.headline)
                    .lineLimit(1)
                
                // Descripción
                Text(bot.botDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                // Modelo e Icono de proveedor
                HStack {
                    Image(AIProvider(rawValue: bot.providerIdentifier)?.iconName ?? "custom-icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    
                    Text(bot.modelIdentifier)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
}

struct BotDetailView: View {
    let bot: Bot
    @State private var showingEditSheet = false
    @State private var showingKnowledgeSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Encabezado del bot
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(bot.name)
                            .font(.largeTitle)
                            .bold()
                        
                        Text(bot.botDescription)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(bot.emoji)
                        .font(.system(size: 60))
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                
                // Información del modelo
                VStack(alignment: .leading, spacing: 8) {
                    Text("Model Information")
                        .font(.headline)
                    
                    HStack {
                        Image(AIProvider(rawValue: bot.providerIdentifier)?.iconName ?? "custom-icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .cornerRadius(4)
                        
                        Text(AIProvider(rawValue: bot.providerIdentifier)?.displayName ?? "Custom")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Image(systemName: "cpu")
                        Text(bot.modelIdentifier)
                            .font(.subheadline)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                
                // System Prompt
                VStack(alignment: .leading, spacing: 8) {
                    Text("System Prompt")
                        .font(.headline)
                    
                    Text(bot.systemPrompt)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                
                // Knowledge Sources
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Knowledge Sources")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            showingKnowledgeSheet = true
                        }) {
                            Image(systemName: "plus.circle")
                        }
                    }
                    
                    if let sources = bot.knowledgeSources, !sources.isEmpty {
                        ForEach(sources) { source in
                            KnowledgeSourceRow(source: source)
                        }
                    } else {
                        Text("No knowledge sources added")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
            }
            .padding()
        }
        .navigationBarTitle("", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit Bot", systemImage: "pencil")
                    }
                    
                    Button {
                        // Iniciar un chat con este bot
                    } label: {
                        Label("Start Chat", systemImage: "bubble.right")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        // Eliminar bot
                    } label: {
                        Label("Delete Bot", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}

struct KnowledgeSourceRow: View {
    let source: KnowledgeSource
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(source.name)
                .font(.subheadline)
                .bold()
            
            Text(source.content.prefix(100) + (source.content.count > 100 ? "..." : ""))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct NewBotView: View {
    @State private var name: String = ""
    @State private var emoji: String = "🤖"
    @State private var description: String = ""
    @State private var systemPrompt: String = "You are a helpful AI assistant."
    @State private var selectedProvider: AIProvider = .openAI
    @State private var selectedModel: String = "gpt-4o"
    @State private var emojiPickerVisible: Bool = false
    
    // Simulación de modelos disponibles para cada proveedor
    private let models: [AIProvider: [String]] = [
        .openAI: ["gpt-4o", "gpt-4-turbo", "gpt-3.5-turbo"],
        .anthropic: ["claude-3-opus", "claude-3-sonnet", "claude-3-haiku"],
        .groq: ["llama-3-8b", "mixtral-8x7b"],
        .perplexity: ["pplx-7b-online", "pplx-70b-online"],
        .deepSeek: ["deepseek-coder", "deepseek-chat"],
        .openRouter: ["openai/gpt-4", "anthropic/claude-3-opus", "google/gemini-pro"]
    ]
    
    var onCreateBot: (String, String, String, String, AIProvider, String) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Bot Information")) {
                    TextField("Name", text: $name)
                    
                    Button(action: {
                        emojiPickerVisible.toggle()
                    }) {
                        HStack {
                            Text("Emoji")
                            Spacer()
                            Text(emoji)
                                .font(.system(size: 24))
                        }
                    }
                    
                    if emojiPickerVisible {
                        EmojiPicker(selectedEmoji: $emoji)
                            .frame(height: 200)
                    }
                    
                    TextField("Description", text: $description)
                        .frame(height: 80)
                }
                
                Section(header: Text("Provider & Model")) {
                    Picker("Provider", selection: $selectedProvider) {
                        ForEach(AIProvider.allCases) { provider in
                            if provider != .custom {
                                Text(provider.displayName)
                                    .tag(provider)
                            }
                        }
                    }
                    .onChange(of: selectedProvider) { _, newValue in
                        if let availableModels = models[newValue], !availableModels.isEmpty {
                            selectedModel = availableModels[0]
                        }
                    }
                    
                    Picker("Model", selection: $selectedModel) {
                        if let availableModels = models[selectedProvider] {
                            ForEach(availableModels, id: \.self) { model in
                                Text(model)
                                    .tag(model)
                            }
                        }
                    }
                }
                
                Section(header: Text("System Prompt")) {
                    TextEditor(text: $systemPrompt)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle("New Bot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        // Cerrar sheet
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreateBot(name, emoji, description, systemPrompt, selectedProvider, selectedModel)
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct EmojiPicker: View {
    @Binding var selectedEmoji: String
    
    // Algunas categorías comunes de emojis
    private let emojis = [
        "🤖", "🦾", "🧠", "💻", "🖥️", "📱", "🤔", "🧐", "😎", "🧙‍♂️",
        "👨‍💻", "👩‍💻", "🔍", "💡", "⚙️", "🧩", "🎮", "🎯", "📊", "📈",
        "🗣️", "💬", "💭", "🔮", "🧿", "👁️", "🦄", "🐱", "🐶", "🦊",
        "🦁", "🐼", "🐯", "🦉", "🐬", "🐢", "🐙", "🦋", "🦜", "🍀"
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 10) {
                ForEach(emojis, id: \.self) { emoji in
                    Button(action: {
                        selectedEmoji = emoji
                    }) {
                        Text(emoji)
                            .font(.largeTitle)
                            .padding(8)
                            .background(selectedEmoji == emoji ? Color.accentColor.opacity(0.2) : Color.clear)
                            .clipShape(Circle())
                    }
                }
            }
            .padding()
        }
    }
}