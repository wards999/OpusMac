import SwiftUI

struct ContentView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var leftTabs = PaneTabManager(initialURL: FileManager.default.homeDirectoryForCurrentUser)
    @StateObject private var rightTabs = PaneTabManager(
        initialURL: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
    )
    @State private var activeSide: Side = .left
    @State private var treeSelection: URL? = nil
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var showingThemeSettings = false
    @State private var showingSynchronize = false
    @State private var showingFormatPatterns = false
    @State private var showingSettings = false
    @State private var showViewer = true
    @State private var showLeftPane = true
    @State private var showRightPane = true
    @State private var viewerItem: FileItem? = nil
    
    private enum Side { case left, right }
    private var activeTabManager: PaneTabManager { activeSide == .left ? leftTabs : rightTabs }
    private var inactiveTabManager: PaneTabManager { activeSide == .left ? rightTabs : leftTabs }
    private var activeModel: PaneModel? { activeTabManager.selectedPane }
    private var inactiveModel: PaneModel? { inactiveTabManager.selectedPane }
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    ForEach(["Home", "Desktop", "Documents", "Downloads"], id: \.self) { name in
                        Button(name) {
                            let home = FileManager.default.homeDirectoryForCurrentUser
                            let url = name == "Home" ? home : home.appendingPathComponent(name)
                            activeModel?.navigate(to: url)
                        }.buttonStyle(.borderless).font(.caption)
                    }
                    Spacer()
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(themeManager.paneBackground)
                Divider()
                FolderTreeView(selectedURL: $treeSelection) { url in activeModel?.navigate(to: url) }
            }
            .background(themeManager.paneBackground)
            .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 320)
        } detail: {
            HSplitView {
                if showLeftPane {
                    PaneView(
                        tabManager: leftTabs,
                        isActive: activeSide == .left,
                        onActivate: { activeSide = .left },
                        onSwap: { leftTabs.swapContents(with: rightTabs) },
                        onClose: { showLeftPane = false; if !showRightPane { showRightPane = true } }
                    )
                    .frame(minWidth: 240, idealWidth: 480, maxWidth: .infinity, maxHeight: .infinity)
                    .layoutPriority(1)
                }
                if showRightPane {
                    PaneView(
                        tabManager: rightTabs,
                        isActive: activeSide == .right,
                        onActivate: { activeSide = .right },
                        onSwap: { leftTabs.swapContents(with: rightTabs) },
                        onClose: { showRightPane = false; if !showLeftPane { showLeftPane = true } }
                    )
                    .frame(minWidth: 240, idealWidth: 480, maxWidth: .infinity, maxHeight: .infinity)
                    .layoutPriority(1)
                }
                if showViewer {
                    ViewerPane(item: viewerItem)
                        .frame(minWidth: 180, idealWidth: 260, maxWidth: 400, maxHeight: .infinity)
                        .layoutPriority(0.5)
                }
            }
        }
        .background(themeManager.paneBackground)
        .overlay {
            VStack { Spacer(); TransferProgressView().padding() }
            ConflictDialogView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .goBack)) { _ in activeModel?.goBack() }
        .onReceive(NotificationCenter.default.publisher(for: .goForward)) { _ in activeModel?.goForward() }
        .onReceive(NotificationCenter.default.publisher(for: .goUp)) { _ in activeModel?.goUp() }
        .onReceive(NotificationCenter.default.publisher(for: .rememberFormat)) { _ in activeModel?.rememberCurrentFormat() }
        .onReceive(NotificationCenter.default.publisher(for: .clearFormat)) { _ in activeModel?.clearFormat() }
        .onReceive(NotificationCenter.default.publisher(for: .filesDidChange)) { _ in
            if let m = leftTabs.selectedPane { m.navigate(to: m.currentURL) }
            if let m = rightTabs.selectedPane { m.navigate(to: m.currentURL) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openThemeSettings)) { _ in showingThemeSettings = true }
        .onReceive(NotificationCenter.default.publisher(for: .openSynchronize)) { _ in showingSynchronize = true }
        .onReceive(NotificationCenter.default.publisher(for: .openFormatPatterns)) { _ in showingFormatPatterns = true }
        .onReceive(NotificationCenter.default.publisher(for: .openSettings)) { _ in showingSettings = true }
        .onReceive(NotificationCenter.default.publisher(for: .copyToOtherPane)) { _ in
            if let src = activeModel, let dst = inactiveModel { OpusCommands.copyToOtherPane(from: src, to: dst) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .moveToOtherPane)) { _ in
            if let src = activeModel, let dst = inactiveModel { OpusCommands.moveToOtherPane(from: src, to: dst) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .swapPanes)) { _ in
            leftTabs.swapContents(with: rightTabs)
        }
        .onChange(of: leftTabs.selectedPane?.selectedItems) { _, _ in updateViewer() }
        .onChange(of: rightTabs.selectedPane?.selectedItems) { _, _ in updateViewer() }
        .onChange(of: activeSide) { _, _ in updateViewer() }
        .sheet(isPresented: $showingThemeSettings) { ThemeSettingsView().environmentObject(themeManager) }
        .sheet(isPresented: $showingSynchronize) {
            if let left = leftTabs.selectedPane?.currentURL, let right = rightTabs.selectedPane?.currentURL {
                SynchronizeView(leftURL: left, rightURL: right)
            }
        }
        .sheet(isPresented: $showingFormatPatterns) { FormatPatternsView() }
        .sheet(isPresented: $showingSettings) {
            SettingsView().environmentObject(themeManager)
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Text(activeSide == .left ? "Left \u{2192} Right" : "Right \u{2192} Left").font(.caption).foregroundStyle(.secondary)
            }
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    if let src = activeModel, let dst = inactiveModel { OpusCommands.copyToOtherPane(from: src, to: dst) }
                } label: { Label("Copy", systemImage: "doc.on.doc") }
                .disabled(activeModel?.selectedItems.isEmpty ?? true)
                Button {
                    if let src = activeModel, let dst = inactiveModel { OpusCommands.moveToOtherPane(from: src, to: dst) }
                } label: { Label("Move", systemImage: "arrow.right.doc.on.clipboard") }
                .disabled(activeModel?.selectedItems.isEmpty ?? true)
                Button { activeTabManager.addTab() } label: { Label("New Tab", systemImage: "plus.rectangle.on.rectangle") }
                Button {
                    Task {
                        if let model = activeModel {
                            _ = try? FileOperations.createFolder(in: model.currentURL)
                            model.navigate(to: model.currentURL)
                        }
                    }
                } label: { Label("New Folder", systemImage: "folder.badge.plus") }
                Button {
                    guard let model = activeModel, !model.selectedFileItems.isEmpty else { return }
                    try? FileOperations.moveToTrash(model.selectedFileItems)
                    model.navigate(to: model.currentURL)
                    NotificationCenter.default.post(name: .filesDidChange, object: nil)
                } label: { Label("Delete", systemImage: "trash") }
                .disabled(activeModel?.selectedItems.isEmpty ?? true)
                Toggle(isOn: $showViewer) { Label("Viewer", systemImage: "eye") }
                Button { showingSynchronize = true } label: { Label("Synchronize", systemImage: "arrow.triangle.2.circlepath") }
                Button { showingFormatPatterns = true } label: { Label("Format Patterns", systemImage: "folder.badge.gearshape") }
                Button { showingSettings = true } label: { Label("Settings", systemImage: "gear") }
            }
        }
    }
    
    private func updateViewer() { viewerItem = activeModel?.selectedFileItems.first }
}

#Preview {
    ContentView().environmentObject(ThemeManager.shared).frame(width: 1300, height: 800)
}
