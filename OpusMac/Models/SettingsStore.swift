import Foundation
import SwiftUI

struct AppSettings: Codable, Equatable {
    // Appearance
    var themeMode: ThemeMode = .dark
    var accentColor: CodableColor = CodableColor(Color(red: 0.25, green: 0.52, blue: 0.95))
    
    // File Displays
    var defaultViewMode: ViewMode = .details
    var defaultSortColumn: String = "name"
    var defaultSortAscending: Bool = true
    var showHiddenFilesByDefault: Bool = false
    var doubleClickToOpen: Bool = true
    var selectFirstOnNavigate: Bool = false
    
    // File Operations
    var confirmDelete: Bool = true
    var confirmMove: Bool = false
    var dragDefaultIsMove: Bool = true
    var showTransferProgress: Bool = true
    
    // Folders
    var autoSaveFormats: Bool = true
    var maxAutoFormats: Int = 200
    var showPathInTitle: Bool = true
    
    // Folder Tabs
    var showTabBarAlways: Bool = true
    var closeTabOnMiddleClick: Bool = true
    var newTabDuplicatesCurrent: Bool = true
    
    // Folder Tree
    var treeShowHidden: Bool = false
    var treeShowVolumes: Bool = true
    var treeExpandHome: Bool = true
    
    // General
    var startupLeftFolder: String = "~"
    var startupRightFolder: String = "~/Documents"
    var restoreLastSession: Bool = false
    
    static let `default` = AppSettings()
}

@MainActor
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    @Published var settings: AppSettings { didSet { save() } }
    private let fileURL: URL
    
    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("OpusMac", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("Settings.json")
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = decoded
        } else {
            settings = .default
        }
    }
    
    private func save() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
    
    func resetToDefaults() {
        settings = .default
    }
}
