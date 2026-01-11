import SwiftUI

struct ToastView: View {
    let icon: String
    let text: String
    var color: Color = .secondary
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(color)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

struct StatusToastModifier: ViewModifier {
    let isVisible: Bool
    let icon: String
    let text: String
    let color: Color
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            if isVisible {
                ToastView(icon: icon, text: text, color: color)
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: isVisible)
    }
}

extension View {
    func toast(isVisible: Bool, icon: String, text: String, color: Color = .secondary) -> some View {
        modifier(StatusToastModifier(isVisible: isVisible, icon: icon, text: text, color: color))
    }
}
