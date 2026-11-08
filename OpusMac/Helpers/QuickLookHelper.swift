import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Simple Quick Look stand-in that opens the file with the default app
/// or shows a basic viewer. Full QLPreviewController can be re-added once
/// the macOS 26 QuickLookUI module exposure is confirmed.
final class QuickLookHelper: NSObject {
    static let shared = QuickLookHelper()
    
    func preview(urls: [URL], startingAt index: Int = 0) {
        guard !urls.isEmpty else { return }
        let url = urls[min(index, urls.count - 1)]
        NSWorkspace.shared.open(url)
    }
    
    func preview(item: FileItem) {
        preview(urls: [item.url])
    }
}

struct ViewerPane: View {
    @EnvironmentObject var themeManager: ThemeManager
    let item: FileItem?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Preview")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(themeManager.theme.secondaryTextColor.color)
                Spacer()
            }
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(themeManager.paneBackground)
            Divider()
            
            Group {
                if let item {
                    previewContent(for: item)
                } else {
                    ContentUnavailableView("No Selection", systemImage: "eye.slash", description: Text("Select a file to preview"))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(themeManager.listBackground)
        }
        .background(themeManager.listBackground)
    }
    
    @ViewBuilder
    private func previewContent(for item: FileItem) -> some View {
        if item.isDirectory {
            VStack(spacing: 8) {
                Image(systemName: "folder.fill").font(.system(size: 48)).foregroundStyle(themeManager.accent)
                Text(item.name).font(.headline).foregroundStyle(themeManager.theme.textColor.color)
                Text("Folder").foregroundStyle(themeManager.theme.secondaryTextColor.color)
                Text(item.formattedDate).font(.caption).foregroundStyle(themeManager.theme.secondaryTextColor.color)
            }
            .padding()
        } else if item.isImage {
            VStack(spacing: 8) {
                AsyncImage(url: item.url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    case .failure:
                        Image(systemName: "photo").font(.system(size: 48)).foregroundStyle(.secondary)
                    default:
                        ProgressView()
                    }
                }
                Text(item.name).font(.headline).lineLimit(2).foregroundStyle(themeManager.theme.textColor.color)
                Text(item.formattedSize).font(.caption).foregroundStyle(themeManager.theme.secondaryTextColor.color)
                Button("Open") { QuickLookHelper.shared.preview(item: item) }
                    .buttonStyle(.bordered)
            }
            .padding()
        } else {
            VStack(spacing: 8) {
                Image(nsImage: item.icon).resizable().frame(width: 64, height: 64)
                Text(item.name).font(.headline).lineLimit(2).foregroundStyle(themeManager.theme.textColor.color)
                Text(item.kind).foregroundStyle(themeManager.theme.secondaryTextColor.color)
                Text(item.formattedSize).font(.caption).foregroundStyle(themeManager.theme.secondaryTextColor.color)
                Text(item.formattedDate).font(.caption).foregroundStyle(themeManager.theme.secondaryTextColor.color)
                Button("Open") { QuickLookHelper.shared.preview(item: item) }
                    .buttonStyle(.bordered)
            }
            .padding()
        }
    }
}
