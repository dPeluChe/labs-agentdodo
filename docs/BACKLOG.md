# Agent Dodo - Development Backlog

> Epic-based backlog organized by development phases

---

## Phase A: Foundation & UX (MVP Local) ✅ COMPLETE

### Epic 0: DevOps & Quality Assurance
- [x] Configure CI/CD Pipeline
- [x] Configure SwiftLint rules

### Epic 1: Project Foundation & Setup
- [x] Initialize Xcode Project
- [x] Create Data Models (SwiftData: Post, Draft)
- [x] Implement `@ModelActor` for LocalStore

### Epic 2: Core UI - Navigation & Shell
- [x] Main Window & Sidebar Navigation
- [x] App State Management (Global Injection)

### Epic 3: Write View (Composer)
- [x] Basic Composer UI (TextEditor, Char Counter, Progress Ring)
- [x] Composer Actions (Post Logic, Validation, ⌘+Enter)
- [x] Tone Selector (UI + Logic with SF Symbols)
- [x] Save Draft (⌘+S keyboard shortcut)
- [x] Minimal UI Redesign (floating toolbar, distraction-free)
- [x] Quick Composer Panel (⌘+⇧+N floating window)
- [x] Drag & Drop Media Support

### Epic 4: Drafts View
- [x] Draft List View (with empty state)
- [x] Draft Actions (Swipe-to-Delete)
- [x] Edit Draft (load into Composer)

### Epic 5: History View
- [x] Post History List (with status badges)
- [x] Post Row Component (metadata, tone, timestamps)

### Epic 6: Settings & Placeholder Views
- [x] Inbox View (Coming Soon state)
- [x] Explore View (Coming Soon state with search bar)
- [x] Settings View (Tabbed: General, Connections, Composer, About)

---

## Phase B: API Infrastructure ✅ COMPLETE

### Epic 7: Core Networking
- [x] APIClient with async/await
- [x] APIEndpoint protocol
- [x] APIError with retry logic
- [x] KeychainManager for secure storage

### Epic 8: X (Twitter) API
- [x] OAuth 2.0 PKCE implementation
- [x] XAPIClient with token management
- [x] Endpoints: tweets, users, timeline, mentions, media

### Epic 9: LLM Providers
- [x] OllamaClient (local LLM)
- [x] GeminiClient (Google AI)
- [x] LLMProvider unified interface
- [x] LLMManager with provider switching
- [x] AIAssistantTask presets (improve, variations, hashtags)

### Epic 10: Settings - API Connections
- [x] APISettingsView with status indicators
- [x] X API configuration UI
- [x] Ollama connection test
- [x] Gemini API key management

---

## Phase C: Real Integration (Next)

### Epic 11: OAuth Flow
- [ ] ASWebAuthenticationSession for X login
- [ ] Token refresh handling
- [ ] Login/Logout UI flow

### Epic 12: AI Writing Assistant
- [ ] "Improve" button in Composer
- [ ] Streaming response UI
- [ ] Variation suggestions

### Epic 13: Real Posting
- [ ] Post to X via API
- [ ] Media upload flow
- [ ] Error handling (rate limits)
- [ ] Queue management

### Epic 14: Inbox & Mentions
- [ ] Fetch mentions
- [ ] Reply functionality
- [ ] DM support

---

**Current Status:** Phase B Complete. Ready to start Phase C (Real Integration).
