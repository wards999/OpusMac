import SwiftUI
import UniformTypeIdentifiers

struct PaneView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var tabManager: PaneTabManager
    let isActive: Bool
    var onActivate: () -> Void
    @State private var isTargeted = false
    @State private var dropMode: FileOperations.TransferMode = .move
    @State private var showBatchRename = false
    private var model: PaneModel? { tabManager.selectedPane }
    
    var body: some View {
        VStack(spacing: 0) {
            TabBarView(manager: tabManager, isActive: isActive)
            Divider()
            if let model {
                HStack(spacing: 8) {
                    Button { model.goBack() } label: { Image(systemName: "chevron.left") }.disabled(!model.canGoBack)
                    Button { model.goForward() } label: { Image(systemName: "chevron.right") }.disabled(!model.canGoForward)
                    Button { model.goUp() } label: { Image(systemName: "chevron.up") }
                    Divider().frame(height: 16)
                    Text(model.currentURL.path)
                        .font(.system(.body, design: .monospaced)).lineLimit(1).truncationMode(.head)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Picker("", selection: Binding(get: { model.format.viewMode }, set: { model.setViewMode($0) })) {
                        ForEach(ViewMode.allCases) { mode in Text(mode.displayName).tag(mode) }
                    }.pickerStyle(.segmented).frame(width: 260)
                    Menu {
                        Button("Remember View for this Folder") { model.rememberCurrentFormat() }
                        Button("Clear Format for this Folder") { model.clearFormat() }
                        Divider()
                        Button("Batch Rename\u2026") { if !model.selectedFileItems.isEmpty { showBatchRename = true } }
                            .disabled(model.selectedItems.isEmpty)
                    } label: { Image(systemName: "slider.horizontal.3") }
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(isActive ? themeManager.accent.opacity(0.12) : themeManager.listBackground)
                Divider()
                ZStack {
                    FileListView(model: model, isActive: isActive, onActivate: onActivate,
                        onOpen: { item in
                            if item.isDirectory { model.navigate(to: item.url) }
                            else { FileOperations.open(item) }
                        },
                        onQuickLook: { item in QuickLookHelper.shared.preview(item: item) }
                    )
                    if isTargeted {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(style: StrokeStyle(lineWidth: 3, dash: [8]))
                            .foregroundStyle(themeManager.accent)
                            .background(themeManager.accent.opacity(0.08))
                            .overlay {
                                VStack(spacing: 6) {
                                    Image(systemName: dropMode == .move ? "arrow.right.doc.on.clipboard" : "doc.on.doc").font(.largeTitle)
                                    Text(dropMode == .move ? "Move" : "Copy").font(.headline)
                                }.padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                            }.padding(8)
                    }
                }
                .dropDestination(for: URL.self) { urls, _ in
                    handleDrop(urls: urls, model: model); return true
                } isTargeted: { targeted in
                    isTargeted = targeted
                    dropMode = NSEvent.modifierFlags.contains(.option) ? .copy : .move
                }
                HStack {
                    Text("\(model.items.count) items").font(.caption).foregroundStyle(.secondary)
                    if !model.selectedItems.isEmpty {
                        Text("\u2022 \(model.selectedItems.count) selected").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if isTargeted {
                        Text(dropMode == .move ? "Move" : "Copy").font(.caption.weight(.semibold)).foregroundStyle(themeManager.accent)
                    }
                }
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(themeManager.paneBackground)
            } else {
                ContentUnavailableView("No Tab", systemImage: "tab")
            }
        }
        .background(themeManager.listBackground)
        .overlay(RoundedRectangle(cornerRadius: 0).stroke(isActive ? themeManager.accent.opacity(0.7) : Color.clear, lineWidth: 2))
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
        .onAppear { onActivate() }
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
