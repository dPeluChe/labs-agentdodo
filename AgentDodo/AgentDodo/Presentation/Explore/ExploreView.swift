import SwiftUI

struct ExploreView: View {
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search X...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding()
            
            Divider()
            
            // Empty/Placeholder State
            VStack(spacing: 20) {
                Image(systemName: "safari")
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)
                
                Text("Explore")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text("Discover trending topics, hashtags, and accounts once connected to X.")
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
        }
        .navigationTitle("Explore")
    }
}
