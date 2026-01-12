import SwiftUI
import SwiftData
import Combine

@main
struct AgentDodoApp: App {
    // Shared App State
    @StateObject private var appState = AppState.shared
    
    // Quick Composer Panel Controller
    @StateObject private var quickComposer = QuickComposerPanelController.shared
    
    // Menu Bar Controller
    @StateObject private var menuBar = MenuBarController.shared
    
    // App Delegate for Menu Bar setup
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // SwiftData Container Setup
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PostEntity.self,
            DraftEntity.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            MainComposerView(onDismiss: {})
                .environmentObject(appState)
                .frame(minWidth: 500, minHeight: 400)
                .onAppear {
                    SharedComposerState.shared.configure(with: sharedModelContainer)
                    QuickComposerPanelController.shared.modelContainer = sharedModelContainer
                }
        }
        .modelContainer(sharedModelContainer)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            // File Menu - Quick Post
            CommandGroup(replacing: .newItem) {
                Button("New Post") {
                    quickComposer.show()
                }
                .keyboardShortcut("n", modifiers: [.command])
                
                Button("Quick Post...") {
                    quickComposer.toggle()
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
                
                Divider()
            }
        }
        
        // Settings Window
        Settings {
            SettingsView()
        }
    }
}
