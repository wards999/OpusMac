import Foundation

struct SyncItem: Identifiable, Hashable {
    let id = UUID()
    let relativePath: String
    let sourceURL: URL
    let destURL: URL
    let direction: Direction
    let reason: Reason
    let size: Int64?
    enum Direction: String { case leftToRight = "\u2192", rightToLeft = "\u2190", both = "\u2194" }
    enum Reason: String {
        case missingOnRight = "Missing on right"
        case missingOnLeft = "Missing on left"
        case newerOnLeft = "Newer on left"
        case newerOnRight = "Newer on right"
        case sizeDifferent = "Size different"
    }
}

@MainActor
final class SynchronizeEngine: ObservableObject {
    @Published var items: [SyncItem] = []
    @Published var isScanning = false
    @Published var isSyncing = false
    @Published var progress: Double = 0
    @Published var statusMessage = ""
    
    func compare(left: URL, right: URL) async {
        isScanning = true
        statusMessage = "Scanning\u2026"
        items = []
        defer {
            isScanning = false
            statusMessage = items.isEmpty ? "Folders are identical" : "\(items.count) difference(s)"
        }
        let leftFiles = await collectFiles(under: left)
        let rightFiles = await collectFiles(under: right)
        var result: [SyncItem] = []
        for (rel, leftURL) in leftFiles {
            if rightFiles[rel] == nil {
                let size = (try? leftURL.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init)
                result.append(SyncItem(relativePath: rel, sourceURL: leftURL, destURL: right.appendingPathComponent(rel), direction: .leftToRight, reason: .missingOnRight, size: size))
            } else if let rightURL = rightFiles[rel] {
                let leftVals = try? leftURL.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
                let rightVals = try? rightURL.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
                let leftDate = leftVals?.contentModificationDate ?? .distantPast
                let rightDate = rightVals?.contentModificationDate ?? .distantPast
                let leftSize = leftVals?.fileSize ?? 0
                let rightSize = rightVals?.fileSize ?? 0
                if leftDate > rightDate.addingTimeInterval(2) {
                    result.append(SyncItem(relativePath: rel, sourceURL: leftURL, destURL: rightURL, direction: .leftToRight, reason: .newerOnLeft, size: Int64(leftSize)))
                } else if rightDate > leftDate.addingTimeInterval(2) {
                    result.append(SyncItem(relativePath: rel, sourceURL: rightURL, destURL: leftURL, direction: .rightToLeft, reason: .newerOnRight, size: Int64(rightSize)))
                } else if leftSize != rightSize {
                    result.append(SyncItem(relativePath: rel, sourceURL: leftURL, destURL: rightURL, direction: .leftToRight, reason: .sizeDifferent, size: Int64(leftSize)))
                }
            }
        }
        for (rel, rightURL) in rightFiles {
            if leftFiles[rel] == nil {
                let size = (try? rightURL.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init)
                result.append(SyncItem(relativePath: rel, sourceURL: rightURL, destURL: left.appendingPathComponent(rel), direction: .rightToLeft, reason: .missingOnLeft, size: size))
            }
        }
        items = result.sorted { $0.relativePath.localizedStandardCompare($1.relativePath) == .orderedAscending }
    }
    
    func sync(selected: Set<SyncItem.ID>) async {
        let toSync = items.filter { selected.contains($0.id) }
        guard !toSync.isEmpty else { return }
        isSyncing = true
        progress = 0
        defer { isSyncing = false }
        let fm = FileManager.default
        for (index, item) in toSync.enumerated() {
            statusMessage = item.relativePath
            progress = Double(index) / Double(toSync.count)
            let parent = item.destURL.deletingLastPathComponent()
            try? fm.createDirectory(at: parent, withIntermediateDirectories: true)
            do {
                if fm.fileExists(atPath: item.destURL.path) { try fm.removeItem(at: item.destURL) }
                try fm.copyItem(at: item.sourceURL, to: item.destURL)
            } catch { print("Sync error: \(error)") }
        }
        progress = 1
        statusMessage = "Done"
        items.removeAll { selected.contains($0.id) }
    }
    
    private func collectFiles(under root: URL) async -> [String: URL] {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: root, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) else { return [:] }
        var result: [String: URL] = [:]
        let rootPath = root.path
        for case let url as URL in enumerator {
            let values = try? url.resourceValues(forKeys: [.isDirectoryKey])
            if values?.isDirectory == true { continue }
            var rel = url.path
            if rel.hasPrefix(rootPath) {
                rel = String(rel.dropFirst(rootPath.count))
                if rel.hasPrefix("/") { rel = String(rel.dropFirst()) }
            }
            result[rel] = url
        }
        return result
    }
}
