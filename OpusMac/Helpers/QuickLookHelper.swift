import AppKit
import SwiftUI

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
    let item: FileItem?
    var body: some View {
        Group {
            if let item {
                if item.isDirectory {
                    VStack {
                        Image(systemName: "folder.fill").font(.system(size: 48)).foregroundStyle(.secondary)
                        Text(item.name).font(.headline)
                        Text("Folder").foregroundStyle(.secondary)
                    }
                } else if let uti = item.contentType, uti.conforms(to: .image) {
                    AsyncImage(url: item.url) { phase in
                        switch phase {
                        case .success(let image): image.resizable().aspectRatio(contentMode: .fit)
                        case .failure: Image(systemName: "photo").font(.largeTitle)
                        default: ProgressView()
                        }
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(nsImage: item.icon).resizable().frame(width: 64, height: 64)
                        Text(item.name).font(.headline).lineLimit(2)
                        Text(item.kind).foregroundStyle(.secondary)
                        Text(item.formattedSize).font(.caption).foregroundStyle(.secondary)
                        Button("Open") { QuickLookHelper.shared.preview(item: item) }
                            .buttonStyle(.bordered)
                    }.padding()
                }
            } else {
                ContentUnavailableView("No Selection", systemImage: "eye.slash", description: Text("Select a file to preview"))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}
