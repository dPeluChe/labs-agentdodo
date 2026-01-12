import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selection: DashboardSection? = .history
    @Environment(\.modelContext) private var modelContext
    
    // Dependencies
    private var localStore: LocalStore {
        LocalStore(modelContainer: modelContext.container)
    }
    
    var body: some View {
        NavigationSplitView {
            dashboardSidebar
        } detail: {
            dashboardContent
        }
        .frame(minWidth: 700, minHeight: 500)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Dashboard Sidebar
    
    private var dashboardSidebar: some View {
        List(selection: $selection) {
            Section("Dashboard") {
                ForEach(DashboardSection.allCases, id: \.self) { section in
                    Label(section.title, systemImage: section.icon)
                        .tag(section)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    QuickComposerPanelController.shared.show()
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .help("New Post (⌘⇧N)")
            }
        }
    }
    
    // MARK: - Dashboard Content
    
    @ViewBuilder
    private var dashboardContent: some View {
        switch selection {
        case .history:
            let historyVM = HistoryViewModel(localStore: localStore)
            DashboardHistoryView(viewModel: historyVM)
        case .drafts:
            let draftsVM = DraftsViewModel(localStore: localStore)
            DashboardDraftsView(viewModel: draftsVM)
        case .analytics:
            DashboardAnalyticsView()
        case .settings:
            SettingsView()
        case .none:
            DashboardWelcomeView()
        }
    }
}

// MARK: - Dashboard Sections

enum DashboardSection: CaseIterable {
    case history
    case drafts
    case analytics
    case settings
    
    var title: String {
        switch self {
        case .history: return "History"
        case .drafts: return "Drafts"
        case .analytics: return "Analytics"
        case .settings: return "Settings"
        }
    }
    
    var icon: String {
        switch self {
        case .history: return "clock"
        case .drafts: return "doc.text"
        case .analytics: return "chart.bar"
        case .settings: return "gearshape"
        }
    }
}

// MARK: - Dashboard Views

struct DashboardWelcomeView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bird.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            
            Text("Agent Dodo")
                .font(.title.weight(.semibold))
            
            Text("Your AI-powered social media companion")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Divider()
                .frame(width: 200)
                .padding(.vertical, 8)
            
            Button {
                QuickComposerPanelController.shared.show()
            } label: {
                Label("New Post", systemImage: "square.and.pencil")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DashboardHistoryView: View {
    @ObservedObject var viewModel: HistoryViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Post History")
                    .font(.title2.weight(.semibold))
                Spacer()
                Text("\(viewModel.posts.count) posts")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            
            Divider()
            
            // Content
            if viewModel.posts.isEmpty {
                emptyState
            } else {
                List(viewModel.posts) { post in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(post.text)
                            .lineLimit(2)
                        
                        HStack(spacing: 12) {
                            Label(post.status.rawValue.capitalized, systemImage: statusIcon(post.status))
                                .font(.caption)
                                .foregroundStyle(statusColor(post.status))
                            
                            Text(post.createdAt, style: .relative)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.inset)
            }
        }
        .task {
            await viewModel.loadPosts()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text("No posts yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Your posted content will appear here")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func statusIcon(_ status: PostStatus) -> String {
        switch status {
        case .queued: return "clock"
        case .sent: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.circle.fill"
        }
    }
    
    private func statusColor(_ status: PostStatus) -> Color {
        switch status {
        case .queued: return .orange
        case .sent: return .green
        case .failed: return .red
        }
    }
}

struct DashboardDraftsView: View {
    @ObservedObject var viewModel: DraftsViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Drafts")
                    .font(.title2.weight(.semibold))
                Spacer()
                Text("\(viewModel.drafts.count) drafts")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            
            Divider()
            
            // Content
            if viewModel.drafts.isEmpty {
                emptyState
            } else {
                List(viewModel.drafts) { draft in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(draft.text)
                            .lineLimit(2)
                        
                        HStack(spacing: 12) {
                            Text("\(draft.text.count) characters")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text(draft.updatedAt, style: .relative)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // TODO: Open in composer
                    }
                }
                .listStyle(.inset)
            }
        }
        .task {
            await viewModel.loadDrafts()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text("No drafts")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Saved drafts will appear here")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DashboardAnalyticsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            
            Text("Analytics")
                .font(.title2.weight(.semibold))
            
            Text("Coming soon in Phase C")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
