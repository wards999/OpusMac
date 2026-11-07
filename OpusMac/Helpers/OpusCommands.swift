import Foundation
import AppKit
import SwiftUI

enum OpusCommands {
    
    @MainActor
    static func copyToOtherPane(from source: PaneModel, to destination: PaneModel) {
        let items = source.selectedFileItems
        guard !items.isEmpty else { return }
        Task {
            await TransferManager.shared.transfer(items, to: destination.currentURL, mode: .copy)
            destination.navigate(to: destination.currentURL)
        }
    }
    
    @MainActor
    static func moveToOtherPane(from source: PaneModel, to destination: PaneModel) {
        let items = source.selectedFileItems
        guard !items.isEmpty else { return }
        Task {
            await TransferManager.shared.transfer(items, to: destination.currentURL, mode: .move)
            source.navigate(to: source.currentURL)
            destination.navigate(to: destination.currentURL)
        }
    }
    
    static func openTerminal(at url: URL) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", "Terminal", url.path]
        try? process.run()
    }
}
