import AppKit
import QuickLookUI
import SwiftUI

final class QuickLookHelper: NSObject, QLPreviewControllerDataSource {
    static let shared = QuickLookHelper()
    private var urls: [URL] = []
    private var controller: QLPreviewController?
    
    func preview(urls: [URL], startingAt index: Int = 0) {
        guard !urls.isEmpty else { return }
        self.urls = urls
        let ql = QLPreviewController()
        ql.dataSource = self
        ql.currentPreviewItemIndex = min(index, urls.count - 1)
        if let window = NSApp.keyWindow {
            window.contentViewController?.presentAsModalWindow(ql)
        } else {
            ql.show(nil)
        }
        self.controller = ql
    }
    
    func preview(item: FileItem) {
        preview(urls: [item.url])
    }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int { urls.count }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        urls[index] as QLPreviewItem
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
                        Button("Quick Look") { QuickLookHelper.shared.preview(item: item) }
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
