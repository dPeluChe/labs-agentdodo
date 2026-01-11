import SwiftUI
import AppKit

struct MediaThumbnailView: View {
    let attachment: MediaAttachment
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Thumbnail
            thumbnailContent
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
            
            // Remove button
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .background(Circle().fill(.black.opacity(0.6)))
            }
            .buttonStyle(.plain)
            .offset(x: 6, y: -6)
            
            // Type indicator
            HStack(spacing: 2) {
                Image(systemName: attachment.type.icon)
                    .font(.system(size: 8))
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .offset(x: -4, y: 44)
        }
    }
    
    @ViewBuilder
    private var thumbnailContent: some View {
        if let nsImage = NSImage(contentsOf: attachment.localURL) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            // Fallback for unsupported formats
            VStack(spacing: 4) {
                Image(systemName: attachment.type.icon)
                    .font(.title3)
                Text(attachment.localURL.pathExtension.uppercased())
                    .font(.system(size: 8, weight: .medium))
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.secondary.opacity(0.1))
        }
    }
}
