import SwiftUI

enum SidebarItem: Hashable, Identifiable, CaseIterable {
    case write
    case inbox
    case explore
    case drafts
    case history
    case settings
    
    var id: Self { self }
    
    var title: String {
        switch self {
        case .write: return "Write"
        case .inbox: return "Inbox"
        case .explore: return "Explore"
        case .drafts: return "Drafts"
        case .history: return "History"
        case .settings: return "Settings"
        }
    }
    
    var icon: String {
        switch self {
        case .write: return "square.and.pencil"
        case .inbox: return "tray"
        case .explore: return "safari"
        case .drafts: return "doc.text"
        case .history: return "clock"
        case .settings: return "gear"
        }
    }
}

struct SidebarView: View {
    @Binding var selection: SidebarItem?
    
    var body: some View {
        List(selection: $selection) {
            Section("Main") {
                NavigationLink(value: SidebarItem.write) {
                    Label(SidebarItem.write.title, systemImage: SidebarItem.write.icon)
                }
                NavigationLink(value: SidebarItem.inbox) {
                    Label(SidebarItem.inbox.title, systemImage: SidebarItem.inbox.icon)
                }
                NavigationLink(value: SidebarItem.explore) {
                    Label(SidebarItem.explore.title, systemImage: SidebarItem.explore.icon)
                }
            }
            
            Section("Library") {
                NavigationLink(value: SidebarItem.drafts) {
                    Label(SidebarItem.drafts.title, systemImage: SidebarItem.drafts.icon)
                }
                NavigationLink(value: SidebarItem.history) {
                    Label(SidebarItem.history.title, systemImage: SidebarItem.history.icon)
                }
            }
            
            Section {
                NavigationLink(value: SidebarItem.settings) {
                    Label(SidebarItem.settings.title, systemImage: SidebarItem.settings.icon)
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
    }
}
