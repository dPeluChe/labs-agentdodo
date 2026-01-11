# Agent Dodo - Quick Start Guide

> Get up and running with Agent Dodo in 5 minutes

---

## What You'll Build (MVP - Phase A)

A fully functional macOS app with:
- Composer for writing posts
- Draft management
- Post history
- Mock inbox and explore features
- Settings
- All working with local persistence (no API needed yet)

---

## Prerequisites

Before you begin:
- ✅ macOS 14.0+ (Sonoma or later)
- ✅ Xcode 15.0+
- ✅ Basic Swift and SwiftUI knowledge

---

## Step 1: Create the Xcode Project

### Option A: Using Xcode GUI

1. Open Xcode
2. File → New → Project
3. Choose "macOS" → "App"
4. Configure:
   - **Product Name**: `AgentDodo`
   - **Team**: Your team (or leave as None for now)
   - **Organization Identifier**: `com.yourname` or similar
   - **Bundle Identifier**: `com.yourname.AgentDodo`
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Storage**: SwiftData (Important!)
   - **Include Tests**: ✅ (both Unit and UI)
5. Save in the `labs-agentdodo` directory (choose the existing directory)
6. Xcode will create `AgentDodo.xcodeproj`

### Option B: Using Command Line

```bash
cd /path/to/labs-agentdodo

# Install xcodegen if not already installed
brew install xcodegen

# Create project.yml (we'll provide this)
# Then run:
xcodegen generate

# Open the project
open AgentDodo.xcodeproj
```

---

## Step 2: Configure Project Settings

1. Select the project in the navigator
2. Select the "AgentDodo" target
3. **General** tab:
   - Minimum Deployments: macOS 14.0
   - Deployment Info: Mac Catalyst off, Mac checked
4. **Signing & Capabilities**:
   - Add Capability: "App Sandbox"
   - Enable: "Outgoing Connections (Client)" (for future API calls)
5. **Build Settings**:
   - Swift Language Version: Swift 5

---

## Step 3: Organize Files in Xcode

Move the existing folder structure we created into Xcode:

1. In Xcode's Project Navigator, right-click "AgentDodo" folder
2. Delete the default "ContentView.swift" (Move to Trash)
3. File → Add Files to "AgentDodo"...
4. Select all the folders we created:
   - `AgentDodo/App`
   - `AgentDodo/Presentation`
   - `AgentDodo/ViewModels`
   - `AgentDodo/Domain`
   - `AgentDodo/Infrastructure`
   - `AgentDodo/Resources`
5. Choose: "Create groups" (not folder references)
6. Add to target: AgentDodo

Your project structure should now match our architecture.

---

## Step 4: Create Your First Files

### 4.1: App Entry Point

Create `AgentDodo/App/AgentDodoApp.swift`:

```swift
import SwiftUI
import SwiftData

@main
struct AgentDodoApp: App {
    // MARK: - SwiftData Model Container
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            // Models will be added here as we create them
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer)
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowResizability(.contentSize)
        .commands {
            // Custom menu commands will go here
        }
    }
}
```

### 4.2: Main Content View (Shell)

Create `AgentDodo/App/ContentView.swift`:

```swift
import SwiftUI

struct ContentView: View {
    @State private var selectedSection: SidebarSection = .write

    var body: some View {
        NavigationSplitView {
            // Sidebar
            SidebarView(selection: $selectedSection)
        } detail: {
            // Detail view based on selection
            DetailView(section: selectedSection)
        }
    }
}

// MARK: - Sidebar Section Enum
enum SidebarSection: String, CaseIterable {
    case write = "Write"
    case inbox = "Inbox"
    case explore = "Explore"
    case drafts = "Drafts"
    case history = "History"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .write: return "square.and.pencil"
        case .inbox: return "tray"
        case .explore: return "magnifyingglass"
        case .drafts: return "doc.text"
        case .history: return "clock"
        case .settings: return "gear"
        }
    }
}

#Preview {
    ContentView()
}
```

### 4.3: Sidebar View

Create `AgentDodo/Presentation/Shared/Components/SidebarView.swift`:

```swift
import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarSection

    var body: some View {
        List(SidebarSection.allCases, id: \.self, selection: $selection) { section in
            Label(section.rawValue, systemImage: section.icon)
                .tag(section)
        }
        .navigationTitle("Agent Dodo")
        .frame(minWidth: 200)
    }
}

#Preview {
    SidebarView(selection: .constant(.write))
}
```

### 4.4: Detail View Router

Create `AgentDodo/Presentation/Shared/Components/DetailView.swift`:

```swift
import SwiftUI

struct DetailView: View {
    let section: SidebarSection

    var body: some View {
        Group {
            switch section {
            case .write:
                PlaceholderView(title: "Composer", icon: "square.and.pencil")
            case .inbox:
                PlaceholderView(title: "Inbox", icon: "tray")
            case .explore:
                PlaceholderView(title: "Explore", icon: "magnifyingglass")
            case .drafts:
                PlaceholderView(title: "Drafts", icon: "doc.text")
            case .history:
                PlaceholderView(title: "History", icon: "clock")
            case .settings:
                PlaceholderView(title: "Settings", icon: "gear")
            }
        }
    }
}

// Temporary placeholder view
struct PlaceholderView: View {
    let title: String
    let icon: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title)
                .foregroundStyle(.secondary)
            Text("Coming soon...")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    DetailView(section: .write)
}
```

---

## Step 5: Build and Run

1. Select "My Mac" as the run destination
2. Press ⌘R or click the Play button
3. You should see:
   - A macOS window with sidebar navigation
   - 6 sections in the sidebar
   - Placeholder views for each section

**Congratulations! Your Agent Dodo shell is running! 🎉**

---

## Next Steps

Now that you have the basic shell running, here's what to build next (in order):

### Phase 1: Core Models & Persistence (1-2 days)
1. Create SwiftData entities (Post, Draft, etc.)
2. Create domain models
3. Create mappers
4. Create LocalStore service
5. Test persistence with simple CRUD operations

**Files to create:**
- `Domain/Models/Post.swift`
- `Domain/Models/Draft.swift`
- `Infrastructure/LocalStore/Models/PostEntity.swift`
- `Infrastructure/LocalStore/Models/DraftEntity.swift`
- `Infrastructure/LocalStore/Mappers/PostMapper.swift`
- `Infrastructure/LocalStore/LocalStore.swift`

### Phase 2: Mock Services (1 day)
1. Define service protocols
2. Create mock implementations
3. Add sample data generators

**Files to create:**
- `Domain/Protocols/PostServiceProtocol.swift`
- `Infrastructure/API/MockPostService.swift`
- `Infrastructure/API/MockInboxService.swift`

### Phase 3: Composer (Write View) (2-3 days)
1. Create ComposerViewModel
2. Create ComposerView UI
3. Implement save draft functionality
4. Implement mock post functionality
5. Add character counter
6. Add tone selector (mock)

**Files to create:**
- `ViewModels/ComposerViewModel.swift`
- `Domain/UseCases/CreatePostUseCase.swift`
- `Domain/UseCases/SaveDraftUseCase.swift`
- `Presentation/Write/ComposerView.swift`
- `Presentation/Write/CharacterCounter.swift`
- `Presentation/Write/ToneSelectorView.swift`

### Phase 4: Drafts & History (2 days)
1. Create DraftsViewModel
2. Create DraftsView
3. Create HistoryViewModel
4. Create HistoryView
5. Connect to LocalStore

### Phase 5: Inbox & Explore (Mock) (2-3 days)
1. Create inbox views
2. Create conversation view
3. Create explore/search views
4. Use mock data

### Phase 6: Settings & Polish (1-2 days)
1. Settings view
2. App state management
3. Error handling
4. Loading states
5. Animations

### Phase 7: Quick Composer Window (1-2 days)
1. Floating window implementation
2. Global keyboard shortcut
3. Quick post flow

---

## Development Workflow

### Daily Development
```bash
# 1. Open Xcode
open AgentDodo.xcodeproj

# 2. Pull latest changes (if team)
git pull

# 3. Build (⌘B)
# 4. Run (⌘R)
# 5. Test (⌘U)

# 6. Make changes, commit frequently
git add .
git commit -m "feat: add composer view"
git push
```

### Testing as You Go
- Use SwiftUI Previews for rapid UI iteration
- Write unit tests for ViewModels
- Write UI tests for critical flows
- Run tests frequently (⌘U)

---

## Resources

- **Documentation**: See `docs/` folder
  - `ARCHITECTURE.md` - Technical architecture
  - `BACKLOG.md` - Full development roadmap
  - `DEV_GUIDE.md` - Coding conventions
  - `PRODUCT_PLAN.md` - Product vision

- **Xcode Help**: Help → Search → "SwiftUI" or "SwiftData"

- **SwiftUI Tutorials**: [Apple's SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)

---

## Troubleshooting

### Build Errors
- Clean build folder: Product → Clean Build Folder (⌘⇧K)
- Delete derived data: ~/Library/Developer/Xcode/DerivedData
- Restart Xcode

### SwiftData Issues
- Check that all entities are added to the schema
- Verify `@Model` macro is present
- Check that ModelContainer is injected via `.modelContainer()`

### Preview Issues
- Previews use mock data
- If preview crashes, check for force unwraps
- Use `#Preview` macro (not `PreviewProvider` for new code)

---

## Getting Help

If you're stuck:
1. Check the documentation in `docs/`
2. Search Xcode help (⌘⇧0)
3. Review example code in SwiftUI tutorials
4. Check the backlog for related tasks

---

**Ready to build Agent Dodo! Let's make it happen! 🚀**

Last Updated: 2026-01-11
