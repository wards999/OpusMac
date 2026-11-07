import Foundation
import UniformTypeIdentifiers

enum ArchiveBrowser {
    static func isArchive(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ["zip", "cbz"].contains(ext)
    }
    
    static func listContents(of archiveURL: URL) -> [ArchiveEntry] {
        guard let data = try? Data(contentsOf: archiveURL) else { return [] }
        var entries: [ArchiveEntry] = []
        var offset = 0
        let bytes = [UInt8](data)
        while offset + 30 < bytes.count {
            guard bytes[offset] == 0x50, bytes[offset+1] == 0x4b,
                  bytes[offset+2] == 0x03, bytes[offset+3] == 0x04 else { break }
            let nameLen = Int(bytes[offset+26]) | (Int(bytes[offset+27]) << 8)
            let extraLen = Int(bytes[offset+28]) | (Int(bytes[offset+29]) << 8)
            let compSize = Int(bytes[offset+18]) | (Int(bytes[offset+19]) << 8) |
                           (Int(bytes[offset+20]) << 16) | (Int(bytes[offset+21]) << 24)
            let nameStart = offset + 30
            guard nameStart + nameLen <= bytes.count else { break }
            let nameData = Data(bytes[nameStart ..< nameStart + nameLen])
            let name = String(data: nameData, encoding: .utf8) ?? String(data: nameData, encoding: .isoLatin1) ?? "unknown"
            let isDir = name.hasSuffix("/")
            let displayName = isDir ? String(name.dropLast()) : name
            if !displayName.contains("/") || (isDir && displayName.components(separatedBy: "/").count == 1) {
                entries.append(ArchiveEntry(
                    name: isDir ? displayName : (displayName as NSString).lastPathComponent,
                    fullPath: name,
                    isDirectory: isDir,
                    compressedSize: compSize,
                    archiveURL: archiveURL
                ))
            }
            offset = nameStart + nameLen + extraLen + compSize
        }
        return entries.sorted { a, b in
            if a.isDirectory != b.isDirectory { return a.isDirectory && !b.isDirectory }
            return a.name.localizedStandardCompare(b.name) == .orderedAscending
        }
    }
}

struct ArchiveEntry: Identifiable, Hashable {
    var id: String { fullPath }
    let name: String
    let fullPath: String
    let isDirectory: Bool
    let compressedSize: Int
    let archiveURL: URL
}
