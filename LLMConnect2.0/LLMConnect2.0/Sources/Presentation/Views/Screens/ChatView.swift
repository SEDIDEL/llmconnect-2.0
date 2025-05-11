//
//  ChatView.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @FocusState private var isInputFocused: Bool
    @State private var isPresentingShare = false
    @State private var showingNewFolderSheet = false
    @State private var selectedFolderID: UUID?
    
    var body: some View {
        VStack(spacing: 0) {
            chatMessagesView
            inputView
        }
        .navigationTitle(viewModel.chatTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        viewModel.renameChat()
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    
                    Button {
                        viewModel.pinChat(!viewModel.isPinned)
                    } label: {
                        if viewModel.isPinned {
                            Label("Unpin", systemImage: "pin.slash")
                        } else {
                            Label("Pin", systemImage: "pin")
                        }
                    }
                    
                    Menu("Move to") {
                        Button("New Folder") {
                            showingNewFolderSheet = true
                        }
                        
                        Divider()
                        
                        ForEach(viewModel.folders) { folder in
                            Button(folder.name) {
                                viewModel.moveChat(to: folder.id)
                            }
                        }
                        
                        if !viewModel.folders.isEmpty {
                            Divider()
                            
                            Button("No Folder") {
                                selectedFolderID = nil
                            }
                        }
                    }
                    
                    Button {
                        isPresentingShare = true
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        viewModel.deleteChat()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Rename Chat", isPresented: $viewModel.isShowingRenameDialog) {
            TextField("Chat Title", text: $viewModel.newChatTitle)
            Button("Cancel", role: .cancel) { }
            Button("Rename") {
                viewModel.confirmRename()
            }
        }
        .alert("Delete Chat", isPresented: $viewModel.isShowingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.confirmDelete()
            }
        } message: {
            Text("Are you sure you want to delete this chat? This action cannot be undone.")
        }
        .sheet(isPresented: $viewModel.isShowingNewFolderDialog) {
            newFolderView
        }
        .alert(
            "Error",
            isPresented: Binding<Bool>(
                get: { viewModel.isShowingError },
                set: { viewModel.isShowingError = $0 }
            ),
            presenting: viewModel.errorMessage
        ) { _ in
            Button("OK", role: .cancel) { }
        } message: { message in
            Text(message)
        }
        .sheet(isPresented: $isPresentingShare) {
            let chatText = viewModel.messages.map { "\($0.role.rawValue): \($0.content)" }.joined(separator: "\n\n")
            ActivityView(activityItems: [chatText])
        }
    }
    
    // Chat messages display
    private var chatMessagesView: some View {
        ScrollViewReader { scrollView in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message, showLinkPreview: true)
                            .id(message.id)
                    }
                    
                    if viewModel.isStreaming {
                        MessageBubble(
                            message: Message(
                                role: .assistant,
                                content: viewModel.streamingMessage
                            ),
                            isTyping: true
                        )
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                scrollToBottom(scrollView: scrollView)
            }
            .onChange(of: viewModel.streamingMessage) { _, _ in
                scrollToBottom(scrollView: scrollView)
            }
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // Input area
    private var inputView: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(alignment: .bottom) {
                TextEditor(text: $viewModel.inputMessage)
                    .padding(8)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .frame(minHeight: 40, maxHeight: 120)
                    .focused($isInputFocused)
                    // Improve keyboard handling
                    .ignoresSafeArea(.keyboard, edges: .bottom)

                Button(action: viewModel.sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.accentColor)
                }
                .disabled(viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isStreaming)
                .padding(.bottom, 8) // Add extra padding to avoid constraint conflicts
            }
            .padding(8)
            .background(Color(.secondarySystemBackground))
        }
        // Make sure this avoids keyboard overlay issues
        .padding(.bottom, 1)
    }
    
    private var newFolderView: some View {
        NavigationView {
            Form {
                Section(header: Text("Folder Name")) {
                    TextField("Enter folder name", text: $viewModel.newFolderName)
                }
            }
            .navigationTitle("New Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.isShowingNewFolderDialog = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        viewModel.confirmNewFolder()
                    }
                    .disabled(viewModel.newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func scrollToBottom(scrollView: ScrollViewProxy) {
        if let lastMessage = viewModel.messages.last {
            withAnimation {
                scrollView.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

// Helper for sharing functionality
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Message bubble component
struct MessageBubble: View {
    let message: Message
    var showLinkPreview: Bool = false
    var isTyping: Bool = false
    
    var body: some View {
        HStack {
            if message.role == .assistant {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.role == .user ? .leading : .trailing, spacing: 8) {
                HStack {
                    if message.role == .assistant {
                        Text(message.content)
                            .padding(12)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(16)
                            .foregroundColor(.primary)
                    } else {
                        Text(message.content)
                            .padding(12)
                            .background(Color.accentColor)
                            .cornerRadius(16)
                            .foregroundColor(.white)
                    }
                }
                
                if isTyping {
                    TypingIndicator()
                        .frame(width: 50, height: 30)
                        .padding(.trailing, 8)
                }
                
                // Citation view would go here if present
            }
            
            if message.role == .user {
                Spacer(minLength: 60)
            }
        }
    }
}

// Typing indicator animation
struct TypingIndicator: View {
    @State private var showFirst = false
    @State private var showSecond = false
    @State private var showThird = false
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .frame(width: 8, height: 8)
                .scaleEffect(showFirst ? 1 : 0.5)
                .foregroundColor(.secondary)
            
            Circle()
                .frame(width: 8, height: 8)
                .scaleEffect(showSecond ? 1 : 0.5)
                .foregroundColor(.secondary)
            
            Circle()
                .frame(width: 8, height: 8)
                .scaleEffect(showThird ? 1 : 0.5)
                .foregroundColor(.secondary)
        }
        .onAppear {
            animate()
        }
    }
    
    func animate() {
        withAnimation(Animation.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
            showFirst = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(Animation.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
                showSecond = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(Animation.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
                showThird = true
            }
        }
    }
}