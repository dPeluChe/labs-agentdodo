import SwiftUI

struct CharacterCounterView: View {
    let count: Int
    let limit: Int
    var showNumber: Bool = true
    var size: CGFloat = 20
    
    private var remaining: Int { limit - count }
    private var isOverLimit: Bool { remaining < 0 }
    private var isNearLimit: Bool { remaining < 20 && remaining >= 0 }
    private var progress: Double { Double(min(count, limit)) / Double(limit) }
    
    var body: some View {
        HStack(spacing: 6) {
            CircularProgressView(
                progress: progress,
                isOverLimit: isOverLimit
            )
            .frame(width: size, height: size)
            
            if showNumber && count > 0 {
                Text("\(remaining)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(isOverLimit ? .red : (isNearLimit ? .orange : .secondary))
            }
        }
        .animation(.easeOut(duration: 0.15), value: count)
    }
}

struct CircularProgressView: View {
    let progress: Double
    let isOverLimit: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: 2.5)
            
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    isOverLimit ? Color.red : (progress > 0.9 ? Color.orange : Color.accentColor),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.15), value: progress)
        }
    }
}
