import Foundation
import SwiftUI
import AppKit

@MainActor
final class TransferManager: ObservableObject {
    static let shared = TransferManager()
    @Published var isTransferring = false
    @Published var progress: Double = 0
    @Published var currentFileName = ""
    @Published var totalFiles = 0
    @Published var completedFiles = 0
    @Published var conflictItem: FileItem? = nil
    @Published var conflictDestination: URL? = nil
    
    enum ConflictResolution { case replace, keepBoth, skip, cancel }
    private var resolutionContinuation: CheckedContinuation<ConflictResolution, Never>?
    
    func transfer(_ items: [FileItem], to destination: URL, mode: FileOperations.TransferMode) async {
        guard !items.isEmpty else { return }
        isTransferring = true
        progress = 0
        totalFiles = items.count
        completedFiles = 0
        defer { isTransferring = false; progress = 1; currentFileName = "" }
        for (index, item) in items.enumerated() {
            currentFileName = item.name
            progress = Double(index) / Double(items.count)
            if item.isDirectory {
                let destPath = destination.path
                let srcPath = item.url.path
                if destPath == srcPath || destPath.hasPrefix(srcPath + "/") { continue }
            }
            let target = destination.appendingPathComponent(item.name)
            let exists = FileManager.default.fileExists(atPath: target.path)
            if exists {
                conflictItem = item
                conflictDestination = destination
                let resolution = await waitForConflictResolution()
                conflictItem = nil
                conflictDestination = nil
                switch resolution {
                case .replace:
                    try? FileManager.default.removeItem(at: target)
                    _ = FileOperations.transfer([item], to: destination, mode: mode)
                case .keepBoth:
                    _ = FileOperations.transfer([item], to: destination, mode: mode)
                case .skip: break
                case .cancel: return
                }
            } else {
                _ = FileOperations.transfer([item], to: destination, mode: mode)
            }
            completedFiles = index + 1
        }
        NotificationCenter.default.post(name: .filesDidChange, object: nil)
    }
    
    private func waitForConflictResolution() async -> ConflictResolution {
        await withCheckedContinuation { continuation in
            resolutionContinuation = continuation
        }
    }
    
    func resolveConflict(_ resolution: ConflictResolution) {
        resolutionContinuation?.resume(returning: resolution)
        resolutionContinuation = nil
    }
}

struct ConflictDialogView: View {
    @ObservedObject var manager = TransferManager.shared
    var body: some View {
        if let item = manager.conflictItem {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 40)).foregroundStyle(.orange)
                Text("File already exists").font(.headline)
                Text("\u{201C}\(item.name)\u{201D} already exists in the destination folder.").multilineTextAlignment(.center).foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    Button("Skip") { manager.resolveConflict(.skip) }.keyboardShortcut(.cancelAction)
                    Button("Keep Both") { manager.resolveConflict(.keepBoth) }
                    Button("Replace") { manager.resolveConflict(.replace) }.keyboardShortcut(.defaultAction)
                    Button("Cancel") { manager.resolveConflict(.cancel) }
                }
            }
            .padding(24).frame(width: 360)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct TransferProgressView: View {
    @ObservedObject var manager = TransferManager.shared
    var body: some View {
        if manager.isTransferring {
            VStack(spacing: 10) {
                ProgressView(value: manager.progress).progressViewStyle(.linear)
                Text(manager.currentFileName).font(.caption).lineLimit(1)
                Text("\(manager.completedFiles) of \(manager.totalFiles)").font(.caption2).foregroundStyle(.secondary)
            }
            .padding().frame(width: 280)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            .shadow(radius: 8)
        }
    }
}
