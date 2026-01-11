import Foundation
import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isOnline: Bool = true
    @Published var showQuickComposer: Bool = false
    
    static let shared = AppState()
    
    private init() {}
}
