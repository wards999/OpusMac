import Foundation
import AppKit
import UniformTypeIdentifiers

struct FileItem: Identifiable, Hashable {
    let id: URL
    let url: URL
    let name: String
    let isDirectory: Bool
    let size: Int64?
    let dateModified: Date?
    let dateCreated: Date?
    let contentType: UTType?
    
    // Cached values to avoid regenerating on every render
    private(set) var cachedIcon: NSImage?
    private(set) var cachedDateModified: String?
    private(set) var cachedDateCreated: String?
    
    var icon: NSImage {
        if let cached = cachedIcon { return cached }
        let img = NSWorkspace.shared.icon(forFile: url.path)
        return img
    }
    
    mutating func cacheIcon() {
        if cachedIcon == nil {
            cachedIcon = NSWorkspace.shared.icon(forFile: url.path)
        }
    }
    
    var formattedSize: String {
        guard let size else { return isDirectory ? "--" : "0 B" }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var formattedDate: String {
        if let cached = cachedDateModified { return cached }
        guard let dateModified else { return "--" }
        return Self.dateFormatter.string(from: dateModified)
    }
    
    var dateCreatedString: String {
        if let cached = cachedDateCreated { return cached }
        guard let dateCreated else { return "--" }
        return Self.dateFormatter.string(from: dateCreated)
    }
    
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()
    
    var kind: String {
        if isDirectory { return "Folder" }
        return contentType?.localizedDescription ?? "Document"
    }
    
    var isImage: Bool {
        contentType?.conforms(to: .image) ?? false
    }
    
    static func from(url: URL) -> FileItem? {
        let keys: Set<URLResourceKey> = [
            .isDirectoryKey,
            .totalFileSizeKey,
            .contentModificationDateKey,
            .creationDateKey,
            .contentTypeKey
        ]
        guard let values = try? url.resourceValues(forKeys: keys) else { return nil }
        var item = FileItem(
            id: url,
            url: url,
            name: url.lastPathComponent,
            isDirectory: values.isDirectory ?? false,
            size: values.totalFileSize.map(Int64.init),
            dateModified: values.contentModificationDate,
            dateCreated: values.creationDate,
            contentType: values.contentType,
            cachedIcon: nil,
            cachedDateModified: nil,
            cachedDateCreated: nil
        )
        item.cacheIcon()
        if let d = item.dateModified { item.cachedDateModified = Self.dateFormatter.string(from: d) }
        if let d = item.dateCreated { item.cachedDateCreated = Self.dateFormatter.string(from: d) }
        return item
    }
}

// Simple thumbnail cache
actor ThumbnailCache {
    static let shared = ThumbnailCache()
    private var cache: [URL: NSImage] = [:]
    
    func thumbnail(for url: URL, size: CGFloat) async -> NSImage? {
        if let existing = cache[url] { return existing }
        guard let image = NSImage(contentsOf: url) else { return nil }
        let thumb = image.resized(to: NSSize(width: size, height: size))
        cache[url] = thumb
        return thumb
    }
}

extension NSImage {
    func resized(to size: NSSize) -> NSImage {
        let newImage = NSImage(size: size)
        newImage.lockFocus()
        draw(in: NSRect(origin: .zero, size: size),
             from: NSRect(origin: .zero, size: self.size),
             operation: .copy,
             fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }
}
