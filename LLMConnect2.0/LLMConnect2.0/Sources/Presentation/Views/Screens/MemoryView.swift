//
//  MemoryView.swift
//  LLMConnect2.0
//
//  Created on 10/05/25.
//

import SwiftUI

struct MemoryView: View {
    @StateObject var viewModel: MemoryViewModel
    @State private var showingNewMemorySheet = false
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .padding()
            } else if viewModel.memories.isEmpty {
                emptyStateView
            } else {
                memoryListContent
            }
        }
        .navigationTitle("Memory")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingNewMemorySheet = true
                }) {
                    Label("New Memory", systemImage: "plus.circle")
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search memories")
        .onChange(of: viewModel.searchText) { _, newValue in
            if newValue.isEmpty {
                viewModel.loadMemories()
            } else {
                viewModel.searchMemories()
            }
        }
        .sheet(isPresented: $showingNewMemorySheet) {
            NewMemoryView { title, content, tags in
                _ = viewModel.createMemory(title: title, content: content, tags: tags)
                showingNewMemorySheet = false
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
    
    private var memoryListContent: some View {
        List {
            ForEach(viewModel.memories) { memory in
                NavigationLink(destination: MemoryDetailView(memory: memory, viewModel: viewModel)) {
                    MemoryRow(memory: memory)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        viewModel.deleteMemory(memory)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .contextMenu {
                    Button {
                        // Navegar a editar memoria
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button {
                        // Copiar al portapapeles
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        viewModel.deleteMemory(memory)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain")
                .font(.system(size: 72))
                .foregroundColor(.gray)
            
            Text("No memories yet")
                .font(.title2)
                .bold()
            
            Text("Add information that can be used in conversations")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button(action: {
                showingNewMemorySheet = true
            }) {
                Text("Create Memory")
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

struct MemoryRow: View {
    let memory: Memory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(memory.title)
                .font(.headline)
            
            Text(memory.content.prefix(100) + (memory.content.count > 100 ? "..." : ""))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            if !memory.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(memory.tags, id: \.self) { tag in
                            Text(tag)
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
            
            Text(formatDate(memory.updatedAt))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct MemoryDetailView: View {
    let memory: Memory
    let viewModel: MemoryViewModel
    @State private var isEditing = false
    @State private var editedTitle: String = ""
    @State private var editedContent: String = ""
    @State private var editedTags: [String] = []
    @State private var newTag: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isEditing {
                    editView
                } else {
                    displayView
                }
            }
            .padding()
        }
        .navigationTitle(isEditing ? "Edit Memory" : "Memory")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isEditing {
                    Button("Save") {
                        saveChanges()
                    }
                } else {
                    Button("Edit") {
                        startEditing()
                    }
                }
            }
            
            if isEditing {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isEditing = false
                    }
                }
            }
        }
    }
    
    private var displayView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(memory.title)
                .font(.title)
                .bold()
            
            Text(memory.content)
                .font(.body)
            
            if !memory.tags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tags")
                        .font(.headline)
                    
                    FlowLayout {
                        ForEach(memory.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.subheadline)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.accentColor.opacity(0.2))
                                .foregroundColor(.accentColor)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            HStack {
                Text("Created:")
                    .fontWeight(.medium)
                Text(formatDate(memory.createdAt))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Updated:")
                    .fontWeight(.medium)
                Text(formatDate(memory.updatedAt))
                    .foregroundColor(.secondary)
            }
            .font(.caption)
            .padding(.top, 8)
        }
    }
    
    private var editView: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField("Title", text: $editedTitle)
                .font(.title3)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Text("Content")
                .font(.headline)
            
            TextEditor(text: $editedContent)
                .frame(minHeight: 150)
                .padding(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Tags")
                    .font(.headline)
                
                FlowLayout {
                    ForEach(editedTags, id: \.self) { tag in
                        HStack(spacing: 4) {
                            Text(tag)
                                .font(.subheadline)
                            
                            Button(action: {
                                editedTags.removeAll { $0 == tag }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.2))
                        .foregroundColor(.accentColor)
                        .cornerRadius(8)
                    }
                }
                
                HStack {
                    TextField("New tag", text: $newTag)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: addTag) {
                        Text("Add")
                    }
                    .disabled(newTag.isEmpty)
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func startEditing() {
        editedTitle = memory.title
        editedContent = memory.content
        editedTags = memory.tags
        isEditing = true
    }
    
    private func addTag() {
        guard !newTag.isEmpty else { return }
        
        let tag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tag.isEmpty && !editedTags.contains(tag) {
            editedTags.append(tag)
        }
        
        newTag = ""
    }
    
    private func saveChanges() {
        let updatedMemory = Memory(
            id: memory.id,
            title: editedTitle,
            content: editedContent,
            tags: editedTags
        )
        // Preserve the original creation date when updating
        updatedMemory.createdAt = memory.createdAt
        updatedMemory.updatedAt = Date()

        viewModel.updateMemory(updatedMemory)
        isEditing = false
    }
}

struct NewMemoryView: View {
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var tags: [String] = []
    @State private var newTag: String = ""
    
    var onCreateMemory: (String, String, [String]) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Memory Details")) {
                    TextField("Title", text: $title)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Content")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $content)
                            .frame(minHeight: 150)
                    }
                }
                
                Section(header: Text("Tags")) {
                    FlowLayout {
                        ForEach(tags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text(tag)
                                    .font(.subheadline)
                                
                                Button(action: {
                                    tags.removeAll { $0 == tag }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.accentColor.opacity(0.2))
                            .foregroundColor(.accentColor)
                            .cornerRadius(8)
                        }
                    }
                    
                    HStack {
                        TextField("New tag", text: $newTag)
                        
                        Button(action: addTag) {
                            Text("Add")
                        }
                        .disabled(newTag.isEmpty)
                    }
                }
            }
            .navigationTitle("New Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        // Cerrar sheet
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreateMemory(title, content, tags)
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                }
            }
        }
    }
    
    private func addTag() {
        guard !newTag.isEmpty else { return }
        
        let tag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tag.isEmpty && !tags.contains(tag) {
            tags.append(tag)
        }
        
        newTag = ""
    }
}

// Un componente para organizar etiquetas en varias líneas (flow layout)
struct FlowLayout<Content: View>: View {
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            FlowLayoutHelper(
                width: geometry.size.width,
                content: content()
            )
        }
    }
}

struct FlowLayoutHelper<Content: View>: View {
    let width: CGFloat
    let content: Content
    
    @State private var elementsSize: [CGSize] = []
    
    var body: some View {
        let stack = HStack(alignment: .top, spacing: 8) {
            content
                .fixedSize()
                .readSize { size in
                    // Esto se llama para cada elemento
                    elementsSize.append(size)
                }
        }
        
        return stack
            .hidden()
            .overlayPreferenceValue(WidthPreferenceKey.self) { _ in
                if elementsSize.isEmpty {
                    content
                } else {
                    FlowLayoutContent(width: width, elementsSize: elementsSize) {
                        content
                    }
                }
            }
    }
}

struct FlowLayoutContent<Content: View>: View {
    let width: CGFloat
    let elementsSize: [CGSize]
    let content: Content

    @State private var positions: [CGPoint] = []
    @State private var height: CGFloat = 0

    // Fixed initializer to properly handle content
    init(width: CGFloat, elementsSize: [CGSize], @ViewBuilder content: () -> Content) {
        self.width = width
        self.elementsSize = elementsSize
        self.content = content()
    }

    var body: some View {
        content
            .hidden()
            .background(calculatePositions())
            .overlayPreferenceValue(ElementPreferenceKey.self) { preferences in
                ZStack(alignment: .topLeading) {
                    ForEach(preferences.indices, id: \.self) { index in
                        preferences[index].view
                            .alignmentGuide(.leading) { _ in
                                -positions[index].x
                            }
                            .alignmentGuide(.top) { _ in
                                -positions[index].y
                            }
                    }
                }
                .frame(height: height)
            }
    }
    
    private func calculatePositions() -> some View {
        EquatableView(content: Color.clear.onAppear {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            var newPositions: [CGPoint] = []
            
            for size in elementsSize {
                if currentX + size.width > width {
                    currentX = 0
                    currentY += lineHeight + 8
                    lineHeight = 0
                }
                
                newPositions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + 8
            }
            
            height = currentY + lineHeight
            positions = newPositions
        })
    }
}

struct WidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ElementPreferenceData {
    let id: Int
    let view: AnyView
}

struct ElementPreferenceKey: PreferenceKey {
    static var defaultValue: [ElementPreferenceData] = []
    
    static func reduce(value: inout [ElementPreferenceData], nextValue: () -> [ElementPreferenceData]) {
        value.append(contentsOf: nextValue())
    }
}

extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct EquatableView<Content: View>: View, Equatable {
    let content: Content
    
    var body: some View {
        content
    }
    
    static func == (lhs: EquatableView<Content>, rhs: EquatableView<Content>) -> Bool {
        return true
    }
}