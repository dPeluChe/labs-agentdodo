import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selection: SidebarItem? = .write
    @State private var editingDraft: Draft?
    @Environment(\.modelContext) private var modelContext
    
    // Dependencies
    private var localStore: LocalStore {
        LocalStore(modelContainer: modelContext.container)
    }
    
    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
        } detail: {
            switch selection {
            case .write:
                composerView
            case .inbox:
                InboxListView()
            case .explore:
                ExploreView()
            case .drafts:
                let draftsVM = DraftsViewModel(localStore: localStore)
                DraftsListView(
                    viewModel: draftsVM,
                    editingDraft: $editingDraft,
                    navigateToWrite: Binding(
                        get: { selection == .write },
                        set: { if $0 { selection = .write } }
                    )
                )
            case .history:
                let historyVM = HistoryViewModel(localStore: localStore)
                HistoryListView(viewModel: historyVM)
            case .settings:
                SettingsView()
            case .none:
                Text("Select an item")
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .onChange(of: selection) { _, newValue in
            // Clear editing draft when navigating away from write
            if newValue != .write {
                editingDraft = nil
            }
        }
    }
    
    // MARK: - Composer View with Draft Support
    
    @ViewBuilder
    private var composerView: some View {
        let createPostUseCase = CreatePostUseCaseImpl(localStore: localStore)
        let saveDraftUseCase = SaveDraftUseCaseImpl(localStore: localStore)
        let viewModel = ComposerViewModel(
            createPostUseCase: createPostUseCase,
            saveDraftUseCase: saveDraftUseCase,
            draft: editingDraft
        )
        ComposerView(viewModel: viewModel)
            .id(editingDraft?.id)
    }
}
