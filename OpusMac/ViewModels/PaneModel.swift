import Foundation
import SwiftUI

@MainActor
final class PaneModel: ObservableObject, Identifiable {
    let id = UUID()
    @Published var currentURL: URL
    @Published var items: [FileItem] = []
    @Published var selectedItems: Set<FileItem.ID> = []
    @Published var format: FolderFormat = .default
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var renamingItem: FileItem? = nil
    @Published var renameText: String = ""
    @Published var archiveURL: URL? = nil
    private var history: [URL] = []
    private var historyIndex = -1
    
    init(url: URL = FileManager.default.homeDirectoryForCurrentUser) {
        self.currentURL = url
        history = [url]
        historyIndex = 0
        Task { await loadDirectory(saveCurrentFormat: false) }
    }
    
    func navigate(to url: URL) {
        let target = url.standardizedFileURL
        if ArchiveBrowser.isArchive(target) {
            archiveURL = target
            currentURL = target
            selectedItems.removeAll()
            Task { await loadArchive() }
            return
        }
        archiveURL = nil
        guard target.path != currentURL.path else { return }
        Task { await FormatStore.shared.save(format, for: currentURL.path) }
        if historyIndex < history.count - 1 {
            history = Array(history.prefix(historyIndex + 1))
        }
        history.append(target)
        historyIndex = history.count - 1
        currentURL = target
        selectedItems.removeAll()
        Task { await loadDirectory(saveCurrentFormat: false) }
    }
    
    func goBack() {
        guard historyIndex > 0 else { return }
        historyIndex -= 1
        let url = history[historyIndex]
        currentURL = url
        archiveURL = ArchiveBrowser.isArchive(url) ? url : nil
        selectedItems.removeAll()
        Task {
            if archiveURL != nil { await loadArchive() }
            else { await loadDirectory(saveCurrentFormat: false) }
        }
    }
    
    func goForward() {
        guard historyIndex < history.count - 1 else { return }
        historyIndex += 1
        let url = history[historyIndex]
        currentURL = url
        archiveURL = ArchiveBrowser.isArchive(url) ? url : nil
        selectedItems.removeAll()
        Task {
            if archiveURL != nil { await loadArchive() }
            else { await loadDirectory(saveCurrentFormat: false) }
        }
    }
    
    func goUp() {
        if archiveURL != nil {
            archiveURL = nil
            navigate(to: currentURL.deletingLastPathComponent())
            return
        }
        let parent = currentURL.deletingLastPathComponent()
        if parent.path != currentURL.path {
            navigate(to: parent)
        }
    }
    
    func goHome() {
        navigate(to: FileManager.default.homeDirectoryForCurrentUser)
    }
    
    var canGoBack: Bool { historyIndex > 0 }
    var canGoForward: Bool { historyIndex < history.count - 1 }
    
    private func loadDirectory(saveCurrentFormat: Bool) async {
        if saveCurrentFormat { await FormatStore.shared.save(format, for: currentURL.path) }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        format = await FormatStore.shared.format(for: currentURL.path)
        
        _ = BookmarkStore.shared.ensureAccess(to: currentURL)
        
        let fm = FileManager.default
        let options: FileManager.DirectoryEnumerationOptions = format.showHiddenFiles ? [] : [.skipsHiddenFiles]
        do {
            if format.flatView {
                items = try await loadFlat(url: currentURL, options: options)
            } else {
                let urls = try fm.contentsOfDirectory(at: currentURL, includingPropertiesForKeys: [.isDirectoryKey, .totalFileSizeKey, .contentModificationDateKey, .creationDateKey, .contentTypeKey], options: options)
                items = sort(urls.compactMap { FileItem.from(url: $0) })
                BookmarkStore.shared.saveBookmark(for: currentURL)
            }
        } catch {
            items = []
            errorMessage = error.localizedDescription
        }
    }
    
    func requestAccessAndReload() {
        if let granted = BookmarkStore.shared.requestAccess(for: currentURL) {
            navigate(to: granted)
        } else {
            Task { await loadDirectory(saveCurrentFormat: false) }
        }
    }
    
    private func loadFlat(url: URL, options: FileManager.DirectoryEnumerationOptions) async throws -> [FileItem] {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.isDirectoryKey, .totalFileSizeKey, .contentModificationDateKey, .creationDateKey, .contentTypeKey], options: options.union([.skipsPackageDescendants])) else { return [] }
        var result: [FileItem] = []
        for case let fileURL as URL in enumerator {
            if let item = FileItem.from(url: fileURL), !item.isDirectory { result.append(item) }
        }
        return sort(result)
    }
    
    private func loadArchive() async {
        isLoading = true
        defer { isLoading = false }
        guard let archive = archiveURL else { return }
        let entries = ArchiveBrowser.listContents(of: archive)
        items = entries.map { entry in
            FileItem(id: archive.appendingPathComponent(entry.fullPath), url: archive.appendingPathComponent(entry.fullPath), name: entry.name, isDirectory: entry.isDirectory, size: Int64(entry.compressedSize), dateModified: nil, dateCreated: nil, contentType: nil)
        }
    }
    
    private func sort(_ items: [FileItem]) -> [FileItem] {
        items.sorted { a, b in
            if a.isDirectory != b.isDirectory { return a.isDirectory && !b.isDirectory }
            let ascending = format.sortAscending
            switch format.sortColumn {
            case "size":
                let sa = a.size ?? -1; let sb = b.size ?? -1
                return ascending ? sa < sb : sa > sb
            case "dateModified":
                let da = a.dateModified ?? .distantPast; let db = b.dateModified ?? .distantPast
                return ascending ? da < db : da > db
            case "kind":
                return ascending ? a.kind.localizedStandardCompare(b.kind) == .orderedAscending : a.kind.localizedStandardCompare(b.kind) == .orderedDescending
            default:
                return ascending ? a.name.localizedStandardCompare(b.name) == .orderedAscending : a.name.localizedStandardCompare(b.name) == .orderedDescending
            }
        }
    }
    
    private func autoSaveFormat() {
        Task { await FormatStore.shared.save(format, for: currentURL.path) }
    }
    
    func rememberCurrentFormat() { autoSaveFormat() }
    func clearFormat() {
        format = .default
        Task { await FormatStore.shared.clear(for: currentURL.path); await loadDirectory(saveCurrentFormat: false) }
    }
    func updateFormat(_ newFormat: FolderFormat) {
        let oldFlat = format.flatView; let oldHidden = format.showHiddenFiles
        format = newFormat
        items = sort(items)
        autoSaveFormat()
        if newFormat.flatView != oldFlat || newFormat.showHiddenFiles != oldHidden {
            Task { await loadDirectory(saveCurrentFormat: false) }
        }
    }
    func setViewMode(_ mode: ViewMode) { var f = format; f.viewMode = mode; updateFormat(f) }
    func toggleFlatView() { var f = format; f.flatView.toggle(); updateFormat(f) }
    func beginRename(_ item: FileItem) { renamingItem = item; renameText = item.name }
    func commitRename() {
        guard let item = renamingItem, !renameText.isEmpty, renameText != item.name else { cancelRename(); return }
        do { try FileOperations.rename(item: item, to: renameText); cancelRename(); Task { await loadDirectory(saveCurrentFormat: false) } }
        catch { errorMessage = error.localizedDescription; cancelRename() }
    }
    func cancelRename() { renamingItem = nil; renameText = "" }
    func select(_ item: FileItem) { selectedItems = [item.id] }
    func toggleSelection(_ item: FileItem) {
        if selectedItems.contains(item.id) { selectedItems.remove(item.id) } else { selectedItems.insert(item.id) }
    }
    var selectedFileItems: [FileItem] { items.filter { selectedItems.contains($0.id) } }
}
