import SwiftUI
import UniformTypeIdentifiers

struct PaneView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var tabManager: PaneTabManager
    let isActive: Bool
    var onActivate: () -> Void
    var onSwap: (() -> Void)? = nil
    var onClose: (() -> Void)? = nil
    @State private var isTargeted = false
    @State private var dropMode: FileOperations.TransferMode = .move
    @State private var showBatchRename = false
    private var model: PaneModel? { tabManager.selectedPane }
    
    private var pathBarBackground: Color {
        isActive
            ? themeManager.accent.opacity(0.55)
            : themeManager.paneBackground
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let model {
                HStack(spacing: 4) {
                    if isActive {
                        Circle()
                            .fill(themeManager.accent)
                            .frame(width: 8, height: 8)
                            .help("Active pane")
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: 8, height: 8)
                    }
                    Button { model.goBack() } label: { Image(systemName: "chevron.left") }
                        .disabled(!model.canGoBack).buttonStyle(.borderless).help("Back")
                    Button { model.goForward() } label: { Image(systemName: "chevron.right") }
                        .disabled(!model.canGoForward).buttonStyle(.borderless).help("Forward")
                    Button { model.goUp() } label: { Image(systemName: "chevron.up") }
                        .buttonStyle(.borderless).help("Up")
                    Button {
                        model.navigate(to: FileManager.default.homeDirectoryForCurrentUser)
                    } label: { Image(systemName: "house") }
                        .buttonStyle(.borderless).help("Home")
                    Divider().frame(height: 14)
                    BreadcrumbBar(url: model.currentURL) { url in model.navigate(to: url) }
                        .frame(maxWidth: .infinity)
                    Picker("", selection: Binding(get: { model.format.viewMode }, set: { model.setViewMode($0) })) {
                        ForEach(ViewMode.allCases) { mode in
                            Label(mode.displayName, systemImage: mode.iconName)
                                .help(mode.displayName)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                    if let onSwap {
                        Button { onSwap() } label: {
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .buttonStyle(.borderless)
                        .help("Swap panes")
                        .frame(width: 20, height: 20)
                    }
                    if let onClose {
                        Button { onClose() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .buttonStyle(.borderless)
                        .help("Close pane")
                        .frame(width: 18, height: 18)
                    }
                    Menu {
                        Button("Remember View for this Folder") { model.rememberCurrentFormat() }
                        Button("Clear Format for this Folder") { model.clearFormat() }
                        Divider()
                        Button("Batch Rename\u{2026}") { if !model.selectedFileItems.isEmpty { showBatchRename = true } }
                            .disabled(model.selectedItems.isEmpty)
                    } label: { Image(systemName: "ellipsis.circle") }
                    .menuStyle(.borderlessButton).frame(width: 22)
                }
                .padding(.horizontal, 6).padding(.vertical, 3)
                .foregroundStyle(themeManager.theme.textColor.color)
                .background(pathBarBackground)
                .contentShape(Rectangle())
                .onTapGesture { onActivate() }
                Divider()
                
                ZStack {
                    themeManager.listBackground
                    FileListView(model: model, isActive: isActive, onActivate: onActivate,
                        onOpen: { item in
                            if item.isDirectory { model.navigate(to: item.url) }
                            else { FileOperations.open(item) }
                        },
                        onQuickLook: { item in QuickLookHelper.shared.preview(item: item) }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onTapGesture { onActivate() }
                    
                    if let error = model.errorMessage, model.items.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "lock.trianglebadge.exclamationmark")
                                .font(.system(size: 32)).foregroundStyle(.secondary)
                            Text("Cannot access folder").font(.headline)
                            Text(error).font(.caption).foregroundStyle(.secondary)
                                .multilineTextAlignment(.center).padding(.horizontal)
                            Button("Grant Access") { model.requestAccessAndReload() }
                                .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(themeManager.listBackground)
                    }
                    
                    if isTargeted {
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                            .foregroundStyle(themeManager.accent)
                            .background(themeManager.accent.opacity(0.08))
                            .overlay {
                                VStack(spacing: 4) {
                                    Image(systemName: dropMode == .move ? "arrow.right.doc.on.clipboard" : "doc.on.doc")
                                    Text(dropMode == .move ? "Move" : "Copy").font(.caption.weight(.semibold))
                                }.padding(8).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                            }.padding(6)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .dropDestination(for: URL.self) { urls, _ in
                    handleDrop(urls: urls, model: model); return true
                } isTargeted: { targeted in
                    isTargeted = targeted
                    dropMode = NSEvent.modifierFlags.contains(.option) ? .copy : .move
                }
                
                HStack(spacing: 8) {
                    Text("\(model.items.count) items")
                        .font(.system(size: 10))
                        .foregroundStyle(themeManager.theme.secondaryTextColor.color)
                    if !model.selectedItems.isEmpty {
                        Text("\(model.selectedItems.count) selected")
                            .font(.system(size: 10))
                            .foregroundStyle(themeManager.theme.secondaryTextColor.color)
                    }
                    Spacer()
                    if isTargeted {
                        Text(dropMode == .move ? "Move" : "Copy")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(themeManager.accent)
                    }
                }
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(isActive ? themeManager.accent.opacity(0.15) : themeManager.paneBackground)
            } else {
                ContentUnavailableView("No Tab", systemImage: "tab")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            Divider()
            TabBarView(manager: tabManager, isActive: isActive)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.listBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(isActive ? themeManager.accent : Color.clear, lineWidth: isActive ? 2 : 0)
                .allowsHitTesting(false)
        )
        .sheet(isPresented: $showBatchRename) {
            if let model, !model.selectedFileItems.isEmpty {
                BatchRenameView(items: model.selectedFileItems) { mapping in
                    for (url, newName) in mapping {
                        if let item = model.selectedFileItems.first(where: { $0.url == url }) {
                            try? FileOperations.rename(item: item, to: newName)
                        }
                    }
                    model.navigate(to: model.currentURL)
                }
            }
        }
    }
    
    private func handleDrop(urls: [URL], model: PaneModel) {
        let items = urls.compactMap { FileItem.from(url: $0) }
        guard !items.isEmpty else { return }
        let mode: FileOperations.TransferMode = NSEvent.modifierFlags.contains(.option) ? .copy : .move
        Task {
            await TransferManager.shared.transfer(items, to: model.currentURL, mode: mode)
            model.navigate(to: model.currentURL)
        }
    }
}

extension Notification.Name {
    static let filesDidChange = Notification.Name("filesDidChange")
}
