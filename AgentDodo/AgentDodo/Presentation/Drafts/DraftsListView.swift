import SwiftUI

struct DraftsListView: View {
    @StateObject var viewModel: DraftsViewModel
    @Binding var editingDraft: Draft?
    @Binding var navigateToWrite: Bool
    
    init(viewModel: DraftsViewModel, editingDraft: Binding<Draft?>, navigateToWrite: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _editingDraft = editingDraft
        _navigateToWrite = navigateToWrite
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading drafts...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.drafts.isEmpty {
                emptyState
            } else {
                draftsList
            }
        }
        .navigationTitle("Drafts")
        .task {
            await viewModel.loadDrafts()
        }
        .refreshable {
            await viewModel.loadDrafts()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("No Drafts")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Save your work in progress here.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Drafts List
    
    private var draftsList: some View {
        List {
            ForEach(viewModel.drafts) { draft in
                DraftRowView(draft: draft)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingDraft = draft
                        navigateToWrite = true
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deleteDraft(draft)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .contextMenu {
                        Button {
                            editingDraft = draft
                            navigateToWrite = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deleteDraft(draft)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.inset)
    }
}

// MARK: - Draft Row View

struct DraftRowView: View {
    let draft: Draft
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: Tone + Updated Date
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: draft.tone.icon)
                        .font(.caption)
                    Text(draft.tone.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.15))
                .clipShape(Capsule())
                
                Spacer()
                
                Text(draft.updatedAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Draft Preview
            Text(draft.text.isEmpty ? "Empty draft" : draft.text)
                .font(.body)
                .foregroundStyle(draft.text.isEmpty ? .secondary : .primary)
                .lineLimit(3)
            
            // Character Count
            HStack {
                Text("\(draft.text.count) / 280 characters")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                if !draft.attachments.isEmpty {
                    Spacer()
                    HStack(spacing: 2) {
                        Image(systemName: "paperclip")
                        Text("\(draft.attachments.count)")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}
