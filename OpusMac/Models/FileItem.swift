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
    
    var icon: NSImage {
        NSWorkspace.shared.icon(forFile: url.path)
    }
    
    var formattedSize: String {
        guard let size else { return isDirectory ? "--" : "0 B" }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var formattedDate: String {
        guard let dateModified else { return "--" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: dateModified)
    }
    
    var dateCreatedString: String {
        guard let dateCreated else { return "--" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: dateCreated)
    }
    
    var kind: String {
        if isDirectory { return "Folder" }
        return contentType?.localizedDescription ?? "Document"
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
        
        return FileItem(
            id: url,
            url: url,
            name: url.lastPathComponent,
            isDirectory: values.isDirectory ?? false,
            size: values.totalFileSize.map(Int64.init),
            dateModified: values.contentModificationDate,
            dateCreated: values.creationDate,
            contentType: values.contentType
        )
    }
}
