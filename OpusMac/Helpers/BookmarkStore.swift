import Foundation
import AppKit

/// Remembers folders the user has allowed so macOS does not re-prompt
/// on every visit within the same session or across launches.
@MainActor
final class BookmarkStore {
    static let shared = BookmarkStore()
    
    private var bookmarks: [String: Data] = [:]
    private var accessedURLs: [String: URL] = [:]
    private let fileURL: URL
    
    private init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("OpusMac", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("Bookmarks.json")
        load()
        restoreAll()
    }
    
    /// Start access for a folder, restoring a saved bookmark if we have one.
    /// Returns true if we believe we can read the folder.
    func ensureAccess(to url: URL) -> Bool {
        let key = normalizedKey(url)
        
        // Already accessing this exact folder
        if let existing = accessedURLs[key], existing.startAccessingSecurityScopedResource() {
            return true
        }
        
        // Try a saved bookmark
        if let data = bookmarks[key] {
            var isStale = false
            if let resolved = try? URL(
                resolvingBookmarkData: data,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ) {
                if resolved.startAccessingSecurityScopedResource() {
                    accessedURLs[key] = resolved
                    if isStale { saveBookmark(for: resolved) }
                    return true
                }
            }
        }
        
        // Walk up to see if a parent bookmark covers this path
        var parent = url.deletingLastPathComponent()
        while parent.path != "/" && parent.path != url.path {
            let parentKey = normalizedKey(parent)
            if let parentURL = accessedURLs[parentKey] {
                _ = parentURL.startAccessingSecurityScopedResource()
                return true
            }
            if let data = bookmarks[parentKey] {
                var isStale = false
                if let resolved = try? URL(
                    resolvingBookmarkData: data,
                    options: .withSecurityScope,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                ), resolved.startAccessingSecurityScopedResource() {
                    accessedURLs[parentKey] = resolved
                    return true
                }
            }
            parent = parent.deletingLastPathComponent()
        }
        
        return false
    }
    
    /// Present a folder picker so the user can grant persistent access.
    func requestAccess(for url: URL) -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = url
        panel.message = "Allow OpusMac to access \(url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent)"
        panel.prompt = "Allow"
        
        guard panel.runModal() == .OK, let selected = panel.url else { return nil }
        saveBookmark(for: selected)
        _ = selected.startAccessingSecurityScopedResource()
        accessedURLs[normalizedKey(selected)] = selected
        return selected
    }
    
    func saveBookmark(for url: URL) {
        do {
            let data = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            bookmarks[normalizedKey(url)] = data
            persist()
        } catch {
            // Non-security-scoped fallback for folders that do not need it
            if let data = try? url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil) {
                bookmarks[normalizedKey(url)] = data
                persist()
            }
        }
    }
    
    private func restoreAll() {
        for (key, data) in bookmarks {
            var isStale = false
            if let resolved = try? URL(
                resolvingBookmarkData: data,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ) {
                if resolved.startAccessingSecurityScopedResource() {
                    accessedURLs[key] = resolved
                }
            }
        }
    }
    
    private func normalizedKey(_ url: URL) -> String {
        url.standardizedFileURL.path
    }
    
    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([String: Data].self, from: data) else { return }
        bookmarks = decoded
    }
    
    private func persist() {
        guard let data = try? JSONEncoder().encode(bookmarks) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
