# Agent Dodo - Technical Architecture

> Detailed technical design and architecture decisions

---

## Architecture Overview

Agent Dodo follows **Clean Architecture** principles with clear separation of concerns across four main layers, optimized for macOS native performance and reliability.

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│           (SwiftUI Views + ViewModels + Shortcuts)       │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│                     Domain Layer                         │
│         (Use Cases + Domain Models + Protocols)          │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│                 Infrastructure Layer                     │
│    (API, LocalStore(Actor), BackgroundTasks, LLM)        │
└──────────────────────────────────────────────────────────┘
```

---

## 1. Presentation Layer

### Responsibility
- Render UI using SwiftUI
- Handle **Keyboard Shortcuts** (macOS First)
- Manage Windowing (`NSPanel` vs `WindowGroup`)
- Display data from ViewModels
- NO business logic

### Key Components
- **ComposerView**: Supports Drag & Drop via `.onDrop(of:delegate:)`.
- **QuickComposerPanel**: Floating `NSPanel` implementation.
- **Shortcuts**: `CMD+Enter` (Send), `CMD+S` (Save), `CMD+N` (New).

---

## 2. ViewModels Layer

### Responsibility
- Manage view state (`@Published`)
- Orchestrate use cases
- Map Domain Errors to UI friendly messages
- **@MainActor** enforced

### ViewModel Pattern

```swift
@MainActor
class ComposerViewModel: ObservableObject {
    @Published var mediaAttachments: [LocalMedia] = []
    
    // ... logic ...

    func handleDrop(providers: [NSItemProvider]) {
        // Handle drag & drop logic, converting to LocalMedia
    }
}
```

---

## 3. Domain Layer

### Responsibility
- Core business logic
- **Provider Agnostic Interfaces**
- Use case orchestration

### Intelligence Layer Abstraction (New)

Instead of hardcoding "Copilot", we define a provider protocol:

```swift
protocol LLMProvider {
    var id: String { get }
    func complete(prompt: String, context: String?) async throws -> String
    func rewrite(text: String, tone: Tone) async throws -> String
}

// This allows swapping OpenAI for Local CoreML later
```

### Domain Models
Models are pure Swift structs, decoupled from SwiftData classes.

---

## 4. Infrastructure Layer

### A. Data Persistence (Concurrency Safe)

We use **SwiftData** with **ModelActors** to ensure thread safety during background operations (like sync).

```swift
import SwiftData

@ModelActor
actor DataStore {
    func savePost(_ post: Post) throws {
        let entity = PostMapper.map(post)
        modelContext.insert(entity)
        try modelContext.save()
    }
    
    func fetchDrafts() throws -> [Draft] {
        // Thread-safe fetch
    }
}
```

**Schema Migration:**
We define a `VersionedSchema` strategy from Day 1 to allow database evolution without data loss.

### B. Networking & Background Tasks

**BackgroundSyncManager**:
Uses `BGTaskScheduler` (or `AppRefresh` on macOS) to keep the inbox updated.

```swift
class BackgroundSyncManager {
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.agentdodo.sync")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        // ...
    }
}
```

### C. LLM Factory

```swift
class LLMFactory {
    static func createProvider(type: LLMProviderType) -> LLMProvider {
        switch type {
        case .openAI: return OpenAIProvider()
        case .anthropic: return AnthropicProvider()
        case .localLlama: return LlamaCppProvider() // Future
        }
    }
}
```

---

## 5. Error Handling Strategy

We map infrastructure errors to domain errors, then to user-facing messages.

| Layer | Error Type | Example |
|-------|------------|---------|
| **Infra** | `HTTPError` | `429 Too Many Requests` |
| **Domain**| `AppError` | `.rateLimited(retryAfter: 300)` |
| **UI** | `Alert` | "You're on fire! 🔥 Please wait 5m to post again." |

---

## 6. Testing Strategy

- **Unit Tests**: ViewModels, UseCases, Mappers.
- **Integration Tests**: `LocalStore` (in-memory SwiftData).
- **Snapshot Tests**: For UI components (ensure pixel perfection).

---

## Summary of Improvements

1. **Concurrency**: Moved from simple context usage to `ModelActor`.
2. **Intelligence**: Abstracted LLM into a Provider pattern.
3. **OS Integration**: Added Background Tasks and Native Drag & Drop specs.
4. **Safety**: Schema Versioning and strict Error Mapping.

**Last Updated:** 2026-01-11