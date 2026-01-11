# Agent Dodo 🦤

> Your intelligent macOS companion for X (Twitter) - Write, read, and engage with AI-powered assistance

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS-blue" alt="Platform: macOS">
  <img src="https://img.shields.io/badge/swift-5.9+-orange" alt="Swift 5.9+">
  <img src="https://img.shields.io/badge/swiftui-latest-brightgreen" alt="SwiftUI">
  <img src="https://img.shields.io/badge/status-MVP-yellow" alt="Status: MVP">
</p>

## What is Agent Dodo?

Agent Dodo is a native macOS application designed to supercharge your X (Twitter) experience. It combines a clean, efficient interface with intelligent features to help you write better posts, manage conversations, and stay on top of your social presence.

### Key Features

- **Smart Composer**: Write posts with AI-powered suggestions and tone adjustments
- **Unified Inbox**: Manage mentions, replies, and DMs in one place
- **Explore & Search**: Discover content and save searches for later
- **Draft Management**: Never lose a thought - save and organize drafts locally
- **Privacy-First**: All data stored locally with Keychain security
- **Quick Access**: Fast composer window accessible from anywhere

## Tech Stack

- **Swift** + **SwiftUI** - Modern, native macOS experience
- **SwiftData** - Local persistence for drafts, history, and cache
- **URLSession** - Robust networking with retry logic and rate limiting
- **Keychain** - Secure token storage
- **OAuth 2.0 PKCE** - Industry-standard authentication

## Project Structure

```
AgentDodo/
├── AgentDodo/                 # Main app target
│   ├── App/                   # App entry point & config
│   ├── Presentation/          # SwiftUI Views
│   │   ├── Write/            # Composer views
│   │   ├── Inbox/            # Inbox & conversation views
│   │   ├── Explore/          # Search & discovery views
│   │   ├── Drafts/           # Draft management
│   │   ├── Settings/         # App settings
│   │   └── Shared/           # Shared UI components
│   ├── ViewModels/           # View models & state management
│   ├── Domain/               # Business logic & use cases
│   │   ├── UseCases/         # App use cases
│   │   └── Models/           # Domain models
│   ├── Infrastructure/       # External services & persistence
│   │   ├── API/              # XAPIClient (real & mock)
│   │   ├── LocalStore/       # SwiftData models & storage
│   │   ├── Auth/             # OAuth & Keychain
│   │   └── Utils/            # Logging, rate limiting, etc.
│   └── Resources/            # Assets, localization
├── AgentDodoTests/           # Unit tests
├── AgentDodoUITests/         # UI tests
└── docs/                     # Documentation
    ├── PRODUCT_PLAN.md       # Product roadmap & architecture
    ├── ARCHITECTURE.md       # Technical architecture details
    └── BACKLOG.md            # Development backlog
```

## Getting Started

### Prerequisites

- macOS 14.0+ (Sonoma or later)
- Xcode 15.0+
- Swift 5.9+

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd labs-agentdodo
```

2. Open the Xcode project:
```bash
open AgentDodo.xcodeproj
```

3. Build and run (⌘R)

### First Launch

On first launch, Agent Dodo will:
1. Initialize local database
2. Load with mock data for exploration
3. Show the onboarding flow

You can explore all features without connecting to X API - perfect for development and testing.

## Development Phases

### Phase A — UI + Mocks + DB (Current)
- [x] Project structure
- [ ] App shell + sidebar navigation
- [ ] Quick Composer window
- [ ] SwiftData models for Drafts + History
- [ ] Mock services for all features
- [ ] Complete write → draft → history flow

### Phase B — Auth + API
- [ ] OAuth PKCE implementation
- [ ] Post creation via X API
- [ ] Error handling & rate limiting
- [ ] Remote ID synchronization

### Phase C — Inbox/Explore
- [ ] Fetch mentions & replies
- [ ] Thread view with context
- [ ] Search with history
- [ ] Timeline cache

### Phase D — AI Copilot
- [ ] Post rewrites & suggestions
- [ ] Tone adjustments
- [ ] Thread idea generation
- [ ] Draft variants

## Architecture Highlights

### Clean Architecture
Agent Dodo follows clean architecture principles with clear separation:
- **Presentation**: SwiftUI views (no business logic)
- **ViewModels**: UI state & user actions
- **Domain**: Pure business logic
- **Infrastructure**: External dependencies (API, DB, Auth)

### Mock-First Development
All services have mock implementations, allowing:
- Full UI development without API access
- Easy testing of edge cases
- Predictable demos
- Seamless swap to real implementations

### Security-First
- OAuth tokens stored in Keychain only
- No sensitive data in logs
- Optional privacy mode
- Data wipe capability

## Documentation

- [Product Plan](docs/PRODUCT_PLAN.md) - Full product vision and roadmap
- [Architecture](docs/ARCHITECTURE.md) - Technical architecture details
- [Backlog](docs/BACKLOG.md) - Development tasks and epics

## Contributing

This is a personal project, but suggestions and feedback are welcome via issues.

## License

[License TBD]

## Acknowledgments

Built with inspiration from the best X/Twitter clients and modern macOS design principles.

---

**Agent Dodo** - Because even your tweets deserve a smart companion 🦤✨
