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
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: Status + Date
            HStack {
                statusBadge
                
                if let url = postURL {
                    Button {
                        openURL(url)
                    } label: {
                        Image(systemName: "arrow.up.right.square")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    .help("Open on X")
                }
                
                Spacer()
                Text(relativeTimestamp(post.createdAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Post Content
            Text(post.text)
                .font(.body)
                .lineLimit(4)
            
            // Footer: Tone
            HStack(spacing: 6) {
                if let tone = post.tone {
                    Image(systemName: tone.icon)
                        .font(.caption)
                    Text(tone.rawValue)
                        .font(.caption)
                }
                
                if let username = post.accountUsername, !username.isEmpty {
                    Text("@\(username)")
                        .font(.caption)
                }
            }
            .foregroundStyle(.secondary)
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
    
    private var postURL: URL? {
        guard post.status == .sent, let remoteId = post.remoteId else { return nil }
        return URL(string: "https://x.com/i/web/status/\(remoteId)")
    }
    
    private func relativeTimestamp(_ date: Date) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.minute, .hour, .day, .weekOfMonth, .month, .year]
        formatter.maximumUnitCount = 1
        let now = Date()
        if now.timeIntervalSince(date) < 60 {
            return "1m"
        }
        return formatter.string(from: date, to: now) ?? "1m"
    }
}
