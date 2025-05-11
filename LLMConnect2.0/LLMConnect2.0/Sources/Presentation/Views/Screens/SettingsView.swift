//
//  SettingsView.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import SwiftUI

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel
    
    var body: some View {
        List {
            // Sección API Keys
            Section(header: Text("API Keys")) {
                NavigationLink(destination: APIKeysView(viewModel: viewModel)) {
                    HStack {
                        Image(systemName: "key")
                            .frame(width: 30, height: 30)
                            .foregroundColor(.accentColor)
                        
                        Text("AI Provider Keys")
                        
                        Spacer()
                        
                        Text("\(viewModel.hasAnyAPIKey ? "✓" : "")")
                            .foregroundColor(.green)
                    }
                }
                
                NavigationLink(destination: CustomProvidersView(viewModel: viewModel)) {
                    HStack {
                        Image(systemName: "server.rack")
                            .frame(width: 30, height: 30)
                            .foregroundColor(.accentColor)
                        
                        Text("Custom Providers")
                        
                        Spacer()
                        
                        Text("\(viewModel.customProviders.count)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Sección Preferencias
            Section(header: Text("Preferences")) {
                NavigationLink(destination: AppearanceView(viewModel: viewModel)) {
                    HStack {
                        Image(systemName: "paintbrush")
                            .frame(width: 30, height: 30)
                            .foregroundColor(.orange)
                        
                        Text("Appearance")
                        
                        Spacer()
                        
                        Text(viewModel.appearance.displayName)
                            .foregroundColor(.secondary)
                    }
                }
                
                NavigationLink(destination: DefaultProviderView(viewModel: viewModel)) {
                    HStack {
                        Image(systemName: "bolt")
                            .frame(width: 30, height: 30)
                            .foregroundColor(.blue)
                        
                        Text("Default Provider")
                        
                        Spacer()
                        
                        Text(viewModel.defaultProvider.displayName)
                            .foregroundColor(.secondary)
                    }
                }
                
                Toggle(isOn: $viewModel.notificationsEnabled) {
                    HStack {
                        Image(systemName: "bell")
                            .frame(width: 30, height: 30)
                            .foregroundColor(.red)
                        
                        Text("Notifications")
                    }
                }
                .onChange(of: viewModel.notificationsEnabled) { _, _ in
                    viewModel.saveNotificationSettings()
                }
            }
            
            // Sección Suscripción
            Section(header: Text("Subscription")) {
                NavigationLink(destination: SubscriptionView(viewModel: viewModel)) {
                    HStack {
                        Image(systemName: "creditcard")
                            .frame(width: 30, height: 30)
                            .foregroundColor(.purple)
                        
                        Text("Subscription Status")
                        
                        Spacer()
                        
                        Text(viewModel.subscriptionStatus.rawValue.capitalized)
                            .foregroundColor(subscriptionStatusColor)
                    }
                }
                
                Button(action: {
                    Task {
                        await viewModel.restorePurchases()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .frame(width: 30, height: 30)
                            .foregroundColor(.gray)
                        
                        Text("Restore Purchases")
                    }
                }
            }
            
            // Sección Acerca de
            Section(header: Text("About")) {
                NavigationLink(destination: AboutView()) {
                    HStack {
                        Image(systemName: "info.circle")
                            .frame(width: 30, height: 30)
                            .foregroundColor(.indigo)
                        
                        Text("About")
                        
                        Spacer()
                        
                        Text("v2.0.0")
                            .foregroundColor(.secondary)
                    }
                }
                
                Link(destination: URL(string: "https://llmconnect.app/privacy")!) {
                    HStack {
                        Image(systemName: "hand.raised")
                            .frame(width: 30, height: 30)
                            .foregroundColor(.green)
                        
                        Text("Privacy Policy")
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.secondary)
                    }
                }
                
                Link(destination: URL(string: "https://llmconnect.app/terms")!) {
                    HStack {
                        Image(systemName: "doc.text")
                            .frame(width: 30, height: 30)
                            .foregroundColor(.green)
                        
                        Text("Terms of Service")
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .overlay {
            if viewModel.isLoading {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle())
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
    
    private var subscriptionStatusColor: Color {
        switch viewModel.subscriptionStatus {
        case .free:
            return .gray
        case .premium:
            return .blue
        case .lifetime:
            return .purple
        }
    }
    
    var hasAnyAPIKey: Bool {
        !viewModel.openAIKey.isEmpty ||
        !viewModel.anthropicKey.isEmpty ||
        !viewModel.groqKey.isEmpty ||
        !viewModel.perplexityKey.isEmpty ||
        !viewModel.deepSeekKey.isEmpty ||
        !viewModel.openRouterKey.isEmpty
    }
}

struct APIKeysView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var selectedProvider = AIProvider.openAI
    @State private var apiKey = ""
    @State private var isValidating = false
    @State private var isValid: Bool? = nil
    
    var body: some View {
        Form {
            Section(header: Text("Select Provider")) {
                Picker("AI Provider", selection: $selectedProvider) {
                    ForEach(AIProvider.allCases) { provider in
                        if provider != .custom {
                            Text(provider.displayName)
                                .tag(provider)
                        }
                    }
                }
                .onChange(of: selectedProvider) { _, newValue in
                    loadAPIKey(for: newValue)
                    isValid = nil
                }
            }
            
            Section(header: Text("API Key")) {
                VStack(alignment: .leading, spacing: 8) {
                    SecureField("Enter API Key", text: $apiKey)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .disabled(isValidating)
                    
                    if isValid != nil {
                        HStack {
                            Image(systemName: isValid == true ? "checkmark.circle" : "xmark.circle")
                                .foregroundColor(isValid == true ? .green : .red)
                            
                            Text(isValid == true ? "Valid API Key" : "Invalid API Key")
                                .font(.caption)
                                .foregroundColor(isValid == true ? .green : .red)
                        }
                    }
                }
                
                if !apiKey.isEmpty {
                    HStack {
                        Button("Validate") {
                            validateAPIKey()
                        }
                        .disabled(apiKey.isEmpty || isValidating)
                        
                        Spacer()
                        
                        if isValidating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                    }
                }
                
                HStack {
                    Button("Save") {
                        viewModel.saveAPIKey(for: selectedProvider, key: apiKey)
                    }
                    .disabled(apiKey.isEmpty)
                    
                    Spacer()
                    
                    Button("Delete") {
                        viewModel.deleteAPIKey(for: selectedProvider)
                        apiKey = ""
                        isValid = nil
                    }
                    .foregroundColor(.red)
                    .disabled(apiKey.isEmpty)
                }
            }
            
            Section(header: Text("Information"), footer: Text("Your API keys are securely stored in the device keychain and are only used for authenticating with the AI provider.")) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("How to get your API key:")
                        .font(.headline)
                    
                    switch selectedProvider {
                    case .openAI:
                        providerInstructions(
                            url: "https://platform.openai.com/api-keys",
                            instructions: ["Go to platform.openai.com", "Sign in to your account", "Navigate to API keys", "Create a new secret key"]
                        )
                    case .anthropic:
                        providerInstructions(
                            url: "https://console.anthropic.com/account/keys",
                            instructions: ["Go to console.anthropic.com", "Sign in to your account", "Navigate to API keys", "Create a new API key"]
                        )
                    case .groq:
                        providerInstructions(
                            url: "https://console.groq.com/keys",
                            instructions: ["Go to console.groq.com", "Sign in to your account", "Navigate to API Keys", "Create a new API key"]
                        )
                    case .perplexity:
                        providerInstructions(
                            url: "https://www.perplexity.ai/settings/api",
                            instructions: ["Go to perplexity.ai", "Sign in to your account", "Navigate to Settings > API", "Create a new API key"]
                        )
                    default:
                        providerInstructions(
                            url: "https://\(selectedProvider.rawValue.lowercased()).com",
                            instructions: ["Go to the provider's website", "Sign in to your account", "Navigate to API keys or settings", "Create a new API key"]
                        )
                    }
                }
            }
        }
        .navigationTitle("\(selectedProvider.displayName) API Key")
        .onAppear {
            loadAPIKey(for: selectedProvider)
        }
    }
    
    private func providerInstructions(url: String, instructions: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(instructions.indices, id: \.self) { index in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(index + 1).")
                        .fontWeight(.bold)
                    Text(instructions[index])
                }
                .font(.caption)
            }
            
            Link("Visit website", destination: URL(string: url)!)
                .font(.caption)
                .padding(.top, 8)
        }
    }
    
    private func loadAPIKey(for provider: AIProvider) {
        switch provider {
        case .openAI:
            apiKey = viewModel.openAIKey
        case .anthropic:
            apiKey = viewModel.anthropicKey
        case .groq:
            apiKey = viewModel.groqKey
        case .perplexity:
            apiKey = viewModel.perplexityKey
        case .deepSeek:
            apiKey = viewModel.deepSeekKey
        case .openRouter:
            apiKey = viewModel.openRouterKey
        case .custom:
            apiKey = ""
        }
    }
    
    private func validateAPIKey() {
        isValidating = true
        isValid = nil
        
        Task {
            let valid = await viewModel.validateAPIKey(for: selectedProvider, key: apiKey)
            
            await MainActor.run {
                isValid = valid
                isValidating = false
            }
        }
    }
}

struct AppearanceView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        Form {
            Section(header: Text("Theme Mode")) {
                Picker("Appearance", selection: $viewModel.appearance) {
                    ForEach(SettingsViewModel.Appearance.allCases) { appearance in
                        Text(appearance.displayName)
                            .tag(appearance)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: viewModel.appearance) { _, _ in
                    viewModel.saveAppearance()
                }
            }
            
            Section(header: Text("Color Theme")) {
                Picker("Theme", selection: $viewModel.themeName) {
                    Text("Default").tag("Default")
                    Text("Dark Blue").tag("DarkBlue")
                    Text("Midnight").tag("Midnight")
                    Text("Purple").tag("Purple")
                    Text("Green").tag("Green")
                }
                .onChange(of: viewModel.themeName) { _, _ in
                    viewModel.saveAppearance()
                }
            }
        }
        .navigationTitle("Appearance")
    }
}

struct DefaultProviderView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        Form {
            Section(header: Text("Default AI Provider")) {
                ForEach(AIProvider.allCases) { provider in
                    if provider != .custom {
                        Button {
                            viewModel.defaultProvider = provider
                            viewModel.saveDefaultProvider()
                        } label: {
                            HStack {
                                Image(provider.iconName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .cornerRadius(4)
                                
                                Text(provider.displayName)
                                
                                Spacer()
                                
                                if viewModel.defaultProvider == provider {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            
            Section(footer: Text("The default provider will be selected automatically when creating new chats. You will need to provide a valid API key for the selected provider.")) {
                // Empty section for footer text
            }
        }
        .navigationTitle("Default Provider")
    }
}

struct CustomProvidersView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var showingAddProviderSheet = false
    
    var body: some View {
        List {
            if viewModel.customProviders.isEmpty {
                Section {
                    Text("No custom providers")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            } else {
                ForEach(viewModel.customProviders, id: \.id) { provider in
                    NavigationLink(destination: CustomProviderDetailView(viewModel: viewModel, provider: provider)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(provider.name)
                                .font(.headline)
                            
                            Text(provider.baseURL.absoluteString)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            viewModel.deleteCustomProvider(id: provider.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("Custom Providers")
        .toolbar {
            ToolbarItem {
                Button {
                    showingAddProviderSheet = true
                } label: {
                    Label("Add Provider", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddProviderSheet) {
            // Custom provider form would go here
            Text("Add Custom Provider")
                .navigationTitle("New Provider")
        }
    }
}

struct CustomProviderDetailView: View {
    @ObservedObject var viewModel: SettingsViewModel
    let provider: SettingsViewModel.CustomProvider
    
    var body: some View {
        Form {
            Section(header: Text("Provider Details")) {
                Text(provider.name)
                    .font(.headline)
                
                Text("Base URL: \(provider.baseURL.absoluteString)")
                    .font(.subheadline)
                
                Text("API Key Header: \(provider.apiKeyName)")
                    .font(.subheadline)
            }
            
            Section(header: Text("Models")) {
                ForEach(provider.models, id: \.id) { model in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.name)
                            .font(.headline)
                        
                        Text("ID: \(model.id)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Max Tokens: \(model.maxTokens)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle(provider.name)
    }
}

struct SubscriptionView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        List {
            // Status section
            Section(header: Text("Current Status")) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.subscriptionStatus.rawValue.capitalized)
                            .font(.headline)
                            .foregroundColor(subscriptionStatusColor)
                        
                        Text(statusDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: statusIcon)
                        .font(.title)
                        .foregroundColor(subscriptionStatusColor)
                }
                .padding(.vertical, 8)
            }
            
            // Plans section
            if viewModel.subscriptionStatus == .free {
                Section(header: Text("Subscription Plans")) {
                    // Monthly plan
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Monthly")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("$4.99")
                                .font(.headline)
                        }
                        
                        Text("Unlimited messages")
                            .font(.caption)
                        
                        Text("Access to all AI models")
                            .font(.caption)
                        
                        Text("Cross-device sync")
                            .font(.caption)
                        
                        Button("Subscribe") {
                            // Implement purchase
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 8)
                    
                    // Yearly plan
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Yearly")
                                .font(.headline)
                            
                            Text("Save 17%")
                                .font(.caption)
                                .padding(4)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                            
                            Spacer()
                            
                            Text("$49.99")
                                .font(.headline)
                        }
                        
                        Text("Unlimited messages")
                            .font(.caption)
                        
                        Text("Access to all AI models")
                            .font(.caption)
                        
                        Text("Cross-device sync")
                            .font(.caption)
                        
                        Button("Subscribe") {
                            // Implement purchase
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 8)
                    
                    // Lifetime plan
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Lifetime")
                                .font(.headline)
                            
                            Text("Best Value")
                                .font(.caption)
                                .padding(4)
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                            
                            Spacer()
                            
                            Text("$99.99")
                                .font(.headline)
                        }
                        
                        Text("One-time purchase")
                            .font(.caption)
                            .bold()
                        
                        Text("Unlimited messages forever")
                            .font(.caption)
                        
                        Text("Access to all current and future AI models")
                            .font(.caption)
                        
                        Button("Purchase") {
                            // Implement purchase
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 8)
                }
            }
            
            // Actions section
            Section {
                Button("Restore Purchases") {
                    Task {
                        await viewModel.restorePurchases()
                    }
                }
                .disabled(viewModel.isLoading)
                
                Link("Manage Subscription", destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
                    .disabled(viewModel.subscriptionStatus == .free)
            }
            
            // Info section
            Section(footer: Text("Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period. You can manage your subscriptions in App Store Settings.")) {
                // Empty section for footer text
            }
        }
        .navigationTitle("Subscription")
    }
    
    private var subscriptionStatusColor: Color {
        switch viewModel.subscriptionStatus {
        case .free:
            return .gray
        case .premium:
            return .blue
        case .lifetime:
            return .purple
        }
    }
    
    private var statusIcon: String {
        switch viewModel.subscriptionStatus {
        case .free:
            return "person"
        case .premium:
            return "star.fill"
        case .lifetime:
            return "crown.fill"
        }
    }
    
    private var statusDescription: String {
        switch viewModel.subscriptionStatus {
        case .free:
            return "Limited access to basic features"
        case .premium:
            return "Full access to all premium features"
        case .lifetime:
            return "Permanent access to all premium features"
        }
    }
}

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    Image("AppIcon")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .cornerRadius(20)
                    
                    Text("LLMConnect")
                        .font(.title)
                        .bold()
                    
                    Text("Version 2.0.0")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            
            Section(header: Text("About")) {
                Text("LLMConnect is a unified client for AI language models, allowing you to chat with multiple AI providers through a single interface.")
                    .padding(.vertical, 8)
            }
            
            Section(header: Text("Developers")) {
                Link(destination: URL(string: "https://twitter.com/llmconnect")!) {
                    HStack {
                        Text("Twitter")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.secondary)
                    }
                }
                
                Link(destination: URL(string: "https://github.com/llmconnect")!) {
                    HStack {
                        Text("GitHub")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.secondary)
                    }
                }
                
                Link(destination: URL(string: "mailto:support@llmconnect.app")!) {
                    HStack {
                        Text("Contact Support")
                        Spacer()
                        Image(systemName: "envelope")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("Legal")) {
                Link(destination: URL(string: "https://llmconnect.app/privacy")!) {
                    HStack {
                        Text("Privacy Policy")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.secondary)
                    }
                }
                
                Link(destination: URL(string: "https://llmconnect.app/terms")!) {
                    HStack {
                        Text("Terms of Service")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.secondary)
                    }
                }
                
                NavigationLink(destination: LicensesView()) {
                    Text("Licenses")
                }
            }
        }
        .navigationTitle("About")
    }
}

struct LicensesView: View {
    let licenses = [
        ("SwiftFormat", "MIT License", "https://github.com/nicklockwood/SwiftFormat"),
        ("SwiftLint", "MIT License", "https://github.com/realm/SwiftLint"),
        ("KeychainAccess", "MIT License", "https://github.com/kishikawakatsumi/KeychainAccess")
    ]
    
    var body: some View {
        List {
            ForEach(licenses, id: \.0) { license in
                VStack(alignment: .leading, spacing: 4) {
                    Text(license.0)
                        .font(.headline)
                    
                    Text(license.1)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Link("View License", destination: URL(string: license.2)!)
                        .font(.caption)
                        .padding(.top, 4)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Licenses")
    }
}