import Foundation
import AppKit

enum FileOperations {
    
    enum TransferMode {
        case move
        case copy
    }
    
    static func open(_ item: FileItem) {
        if item.isDirectory { return }
        NSWorkspace.shared.open(item.url)
    }
    
    static func revealInFinder(_ items: [FileItem]) {
        NSWorkspace.shared.activateFileViewerSelecting(items.map(\.url))
    }
    
    static func moveToTrash(_ items: [FileItem]) throws {
        let fm = FileManager.default
        for item in items {
            try fm.trashItem(at: item.url, resultingItemURL: nil)
        }
    }
    
    static func rename(item: FileItem, to newName: String) throws {
        let fm = FileManager.default
        let newURL = item.url.deletingLastPathComponent().appendingPathComponent(newName)
        try fm.moveItem(at: item.url, to: newURL)
    }
    
    static func createFolder(in parent: URL, name: String = "New Folder") throws -> URL {
        let fm = FileManager.default
        var finalName = name
        var counter = 1
        var target = parent.appendingPathComponent(finalName)
        while fm.fileExists(atPath: target.path) {
            finalName = "\(name) \(counter)"
            target = parent.appendingPathComponent(finalName)
            counter += 1
        }
        try fm.createDirectory(at: target, withIntermediateDirectories: false)
        return target
    }
    
    @discardableResult
    static func transfer(_ items: [FileItem], to destination: URL, mode: TransferMode) -> [Error] {
        let fm = FileManager.default
        var errors: [Error] = []
        for item in items {
            if item.isDirectory {
                let destPath = destination.path
                let srcPath = item.url.path
                if destPath == srcPath || destPath.hasPrefix(srcPath + "/") {
                    errors.append(NSError(domain: "OpusMac", code: 1, userInfo: [
                        NSLocalizedDescriptionKey: "Cannot move/copy a folder into itself"
                    ]))
                    continue
                }
            }
            let target = uniqueTarget(for: item.name, in: destination)
            do {
                switch mode {
                case .move: try fm.moveItem(at: item.url, to: target)
                case .copy: try fm.copyItem(at: item.url, to: target)
                }
            } catch {
                errors.append(error)
            }
        }
        return errors
    }
    
    private static func uniqueTarget(for name: String, in folder: URL) -> URL {
        let fm = FileManager.default
        var candidate = folder.appendingPathComponent(name)
        guard fm.fileExists(atPath: candidate.path) else { return candidate }
        let base = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension
        var counter = 2
        repeat {
            let newName = ext.isEmpty ? "\(base) \(counter)" : "\(base) \(counter).\(ext)"
            candidate = folder.appendingPathComponent(newName)
            counter += 1
        } while fm.fileExists(atPath: candidate.path)
        return candidate
    }
    
    static func move(_ items: [FileItem], to destination: URL) -> [Error] {
        transfer(items, to: destination, mode: .move)
    }
    
    static func copy(_ items: [FileItem], to destination: URL) -> [Error] {
        transfer(items, to: destination, mode: .copy)
    }
}
