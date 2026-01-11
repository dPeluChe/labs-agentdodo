import SwiftUI

struct InboxListView: View {
    var body: some View {
        VStack(spacing: 20) {
            // Empty State Icon
            Image(systemName: "tray")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            
            Text("Inbox")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("Mentions and direct messages will appear here once you connect your X account.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
            
            // Coming Soon Badge
            HStack(spacing: 6) {
                Image(systemName: "clock.badge")
                Text("Coming in Phase B")
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.orange.opacity(0.15))
            .foregroundStyle(.orange)
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Inbox")
    }
}
