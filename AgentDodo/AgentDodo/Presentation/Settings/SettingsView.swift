import SwiftUI

struct SettingsView: View {
    @AppStorage("autoSaveDrafts") private var autoSaveDrafts = true
    @AppStorage("defaultTone") private var defaultTone = "Neutral"
    @AppStorage("showCharacterCount") private var showCharacterCount = true
    @AppStorage("confirmBeforePosting") private var confirmBeforePosting = false
    @AppStorage("quickComposerFloating") private var quickComposerFloating = true
    
    var body: some View {
        TabView {
            // General Settings
            generalSettings
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            // API Connections
            APISettingsView()
                .tabItem {
                    Label("Connections", systemImage: "network")
                }
            
            // Composer Settings
            composerSettings
                .tabItem {
                    Label("Composer", systemImage: "square.and.pencil")
                }
            
            // About
            aboutSection
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 500, height: 420)
    }
    
    // MARK: - General Settings
    
    private var generalSettings: some View {
        Form {
            Section {
                Toggle("Auto-save drafts while typing", isOn: $autoSaveDrafts)
                Toggle("Confirm before posting", isOn: $confirmBeforePosting)
            } header: {
                Text("Behavior")
            }
            
            Section {
                Toggle("Keep Quick Composer floating", isOn: $quickComposerFloating)
            } header: {
                Text("Quick Composer")
            } footer: {
                Text("Access with ⌘⇧N from anywhere in the app")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
    
    // MARK: - Composer Settings
    
    private var composerSettings: some View {
        Form {
            Section {
                Picker("Default Tone", selection: $defaultTone) {
                    ForEach(Tone.allCases) { tone in
                        Label(tone.rawValue, systemImage: tone.icon)
                            .tag(tone.rawValue)
                    }
                }
                .pickerStyle(.menu)
                
                Toggle("Show character counter", isOn: $showCharacterCount)
            } header: {
                Text("Editor")
            }
            
            Section {
                HStack {
                    Text("Post")
                    Spacer()
                    Text("⌘↩")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("Save Draft")
                    Spacer()
                    Text("⌘S")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("Quick Composer")
                    Spacer()
                    Text("⌘⇧N")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Keyboard Shortcuts")
            }
        }
        .formStyle(.grouped)
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // App Icon
            Image(systemName: "bird.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            
            VStack(spacing: 4) {
                Text("Agent Dodo")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Version 1.0.0 (Phase A)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Text("A native macOS client for X with AI intelligence.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
            
            Spacer()
            
            // Status
            HStack(spacing: 8) {
                Circle()
                    .fill(.orange)
                    .frame(width: 8, height: 8)
                Text("API Connection: Not configured")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
