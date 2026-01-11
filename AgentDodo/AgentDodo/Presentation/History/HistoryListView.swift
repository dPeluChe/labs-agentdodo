import SwiftUI

struct HistoryListView: View {
    @StateObject var viewModel: HistoryViewModel
    
    init(viewModel: HistoryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading posts...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.posts.isEmpty {
                emptyState
            } else {
                postsList
            }
        }
        .navigationTitle("History")
        .task {
            await viewModel.loadPosts()
        }
        .refreshable {
            await viewModel.loadPosts()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("No Posts Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Posts you send will appear here.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Posts List
    
    private var postsList: some View {
        List {
            ForEach(viewModel.posts) { post in
                PostRowView(post: post)
            }
        }
        .listStyle(.inset)
    }
}

// MARK: - Post Row View

struct PostRowView: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: Status + Date
            HStack {
                statusBadge
                Spacer()
                Text(post.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Post Content
            Text(post.text)
                .font(.body)
                .lineLimit(4)
            
            // Footer: Tone
            if let tone = post.tone {
                HStack(spacing: 4) {
                    Image(systemName: tone.icon)
                        .font(.caption)
                    Text(tone.rawValue)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(post.status.rawValue.capitalized)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.15))
        .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch post.status {
        case .sent: return .green
        case .queued: return .orange
        case .failed: return .red
        }
    }
}
