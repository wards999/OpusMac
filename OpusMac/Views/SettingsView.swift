import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var store = SettingsStore.shared
    @State private var selection: SettingsPage = .appearance
    @Environment(\.dismiss) private var dismiss
    
    enum SettingsPage: String, CaseIterable, Identifiable {
        case appearance = "Appearance"
        case fileDisplays = "File Displays"
        case fileOperations = "File Operations"
        case folders = "Folders"
        case folderTabs = "Folder Tabs"
        case folderTree = "Folder Tree"
        case general = "General"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .appearance: return "paintpalette"
            case .fileDisplays: return "list.bullet.rectangle"
            case .fileOperations: return "arrow.left.arrow.right"
            case .folders: return "folder"
            case .folderTabs: return "rectangle.stack"
            case .folderTree: return "list.triangle"
            case .general: return "gear"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List(SettingsPage.allCases, selection: $selection) { page in
                Label(page.rawValue, systemImage: page.icon)
                    .tag(page)
            }
            .navigationTitle("Settings")
            .frame(minWidth: 180)
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch selection {
                    case .appearance: appearancePage
                    case .fileDisplays: fileDisplaysPage
                    case .fileOperations: fileOperationsPage
                    case .folders: foldersPage
                    case .folderTabs: folderTabsPage
                    case .folderTree: folderTreePage
                    case .general: generalPage
                    }
                    Spacer()
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(selection.rawValue)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button("Reset to Defaults") { store.resetToDefaults() }
                        .foregroundStyle(.red)
                }
            }
        }
        .frame(minWidth: 700, minHeight: 500)
    }
    
    private var appearancePage: some View {
        Form {
            Picker("Theme", selection: Binding(
                get: { store.settings.themeMode },
                set: { store.settings.themeMode = $0; themeManager.theme.mode = $0 }
            )) {
                ForEach(ThemeMode.allCases) { Text($0.displayName).tag($0) }
            }
            ColorPicker("Accent Color", selection: Binding(
                get: { store.settings.accentColor.color },
                set: {
                    store.settings.accentColor = CodableColor($0)
                    themeManager.theme.accentColor = CodableColor($0)
                }
            ))
            Text("Changes apply immediately.").font(.caption).foregroundStyle(.secondary)
        }
    }
    
    private var fileDisplaysPage: some View {
        Form {
            Picker("Default View Mode", selection: $store.settings.defaultViewMode) {
                ForEach(ViewMode.allCases) { Text($0.displayName).tag($0) }
            }
            Picker("Default Sort", selection: $store.settings.defaultSortColumn) {
                Text("Name").tag("name")
                Text("Size").tag("size")
                Text("Date Modified").tag("dateModified")
                Text("Kind").tag("kind")
            }
            Toggle("Sort Ascending", isOn: $store.settings.defaultSortAscending)
            Toggle("Show Hidden Files by Default", isOn: $store.settings.showHiddenFilesByDefault)
            Toggle("Select First Item on Navigate", isOn: $store.settings.selectFirstOnNavigate)
            Toggle("Double-Click to Open", isOn: $store.settings.doubleClickToOpen)
        }
    }
    
    private var fileOperationsPage: some View {
        Form {
            Toggle("Confirm Delete", isOn: $store.settings.confirmDelete)
            Toggle("Confirm Move", isOn: $store.settings.confirmMove)
            Toggle("Drag Defaults to Move (Option = Copy)", isOn: $store.settings.dragDefaultIsMove)
            Toggle("Show Transfer Progress", isOn: $store.settings.showTransferProgress)
            Text("These control how files are copied, moved, and deleted.").font(.caption).foregroundStyle(.secondary)
        }
    }
    
    private var foldersPage: some View {
        Form {
            TextField("Home Button Folder", text: $store.settings.homeButtonFolder)
                .help("Where the Home button goes. Use ~ for your user folder.")
            Text("Examples: ~  ~/Desktop  ~/Documents  /Volumes/External").font(.caption).foregroundStyle(.secondary)
            Toggle("Automatically Remember Folder Formats", isOn: $store.settings.autoSaveFormats)
            Stepper("Max Auto Formats: \(store.settings.maxAutoFormats)", value: $store.settings.maxAutoFormats, in: 50...1000, step: 50)
            Toggle("Show Path in Window Title", isOn: $store.settings.showPathInTitle)
            Text("Folder formats remember view mode, columns, and sort per folder.").font(.caption).foregroundStyle(.secondary)
        }
    }
    
    private var folderTabsPage: some View {
        Form {
            Toggle("Always Show Tab Bar", isOn: $store.settings.showTabBarAlways)
            Toggle("New Tab Duplicates Current Folder", isOn: $store.settings.newTabDuplicatesCurrent)
            Toggle("Middle-Click Closes Tab", isOn: $store.settings.closeTabOnMiddleClick)
        }
    }
    
    private var folderTreePage: some View {
        Form {
            Toggle("Show Hidden Folders in Tree", isOn: $store.settings.treeShowHidden)
            Toggle("Show Volumes", isOn: $store.settings.treeShowVolumes)
            Toggle("Expand Home on Launch", isOn: $store.settings.treeExpandHome)
        }
    }
    
    private var generalPage: some View {
        Form {
            TextField("Left Pane Startup Folder", text: $store.settings.startupLeftFolder)
            TextField("Right Pane Startup Folder", text: $store.settings.startupRightFolder)
            Toggle("Restore Last Session", isOn: $store.settings.restoreLastSession)
            Text("Use ~ for your home folder.").font(.caption).foregroundStyle(.secondary)
        }
    }
}
