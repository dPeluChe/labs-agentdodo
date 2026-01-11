# Agent Dodo - Development Guide

> Conventions, patterns, and best practices for contributing to Agent Dodo

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Code Style & Linting](#code-style--linting)
3. [Concurrency Guidelines](#concurrency-guidelines)
4. [Project Structure](#project-structure)
5. [Testing Guidelines](#testing-guidelines)
6. [Git Workflow](#git-workflow)

---

## Getting Started

### Prerequisites

- macOS 14.0+ (Sonoma)
- Xcode 15.0+
- Swift 5.9+
- **SwiftLint** (Install via Homebrew: `brew install swiftlint`)

---

## Code Style & Linting

### SwiftLint

We enforce code style using SwiftLint. The `.swiftlint.yml` file in the root directory defines our rules.
**Do not force-push code that breaks the linter.**

Key rules we enforce:
- `force_cast`: Error (Never use `as!`)
- `force_try`: Error (Never use `try!`)
- `line_length`: Warning at 120, Error at 200
- `function_body_length`: Warning at 40 lines (keep functions small!)

### Manual Style Guide

#### Naming & Organization
- Use `// MARK:` to organize large files.
- **ViewModels**: Always implement `ObservableObject`.
- **Properties**: Prefer `let` over `var`.

---

## Concurrency Guidelines

### SwiftData & Actors

SwiftData is **not thread-safe** by default. Never pass `ModelContext` between threads.

**✅ Correct Pattern (ModelActor):**

```swift
@ModelActor
actor DataStore {
    func save(_ item: Item) throws {
        // Runs on the actor's serial executor
        modelContext.insert(item)
        try modelContext.save()
    }
}
```

**❌ Incorrect Pattern:**

```swift
func doBackgroundWork() async {
    let context = container.mainContext // 💥 Unsafe on background thread!
    // ...
}
```

### MainActor

All **ViewModels** and **UI State** must be isolated to the main thread:

```swift
@MainActor
class ComposerViewModel: ObservableObject { ... }
```

---

## Project Structure

### Layer Responsibilities

#### Presentation Layer (`Presentation/`)
- **What**: SwiftUI Views
- **Rules**:
  - No business logic.
  - Use `KeyboardShortcuts` for actions.
  - Use `DragDropDelegate` for media handling.

#### Domain Layer (`Domain/`)
- **What**: Protocols & Pure Logic.
- **Pattern**: Use the **Factory Pattern** for replaceable components (like LLMs).

```swift
// Domain
protocol LLMProvider { ... }

// Infrastructure Factory
class LLMFactory {
    static func create() -> LLMProvider { ... }
}
```

---

## Testing Guidelines

### Unit Tests
- **ViewModels**: Test all `@Published` state changes.
- **Mappers**: Ensure API models map correctly to Domain models.

### Integration Tests
- **SwiftData**: Use an **in-memory** `ModelContainer` configuration for tests.

```swift
let config = ModelConfiguration(isStoredInMemoryOnly: true)
let container = try ModelContainer(for: Schema(...), configurations: [config])
```

---

**Last Updated:** 2026-01-11