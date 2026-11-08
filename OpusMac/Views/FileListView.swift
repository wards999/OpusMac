import SwiftUI
import UniformTypeIdentifiers

struct FileListView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var model: PaneModel
    let isActive: Bool
    var onActivate: () -> Void
    var onOpen: (FileItem) -> Void
    var onQuickLook: (FileItem) -> Void
    @State private var filterText = ""
    @FocusState private var renameFocused: Bool
    @State private var selectionRect: CGRect? = nil
    @State private var dragStart: CGPoint? = nil
    @State private var cellFrames: [FileItem.ID: CGRect] = [:]
    @State private var lastClickID: FileItem.ID?
    @State private var lastClickTime = Date.distantPast
    
    private var filteredItems: [FileItem] {
        guard !filterText.isEmpty else { return model.items }
        return model.items.filter { $0.name.localizedCaseInsensitiveContains(filterText) }
    }
    
    private var visibleColumns: [ColumnConfig] {
        model.format.columns.filter { $0.isVisible }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Filter\u{2026}", text: $filterText).textFieldStyle(.plain)
                if !filterText.isEmpty {
                    Button { filterText = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }.buttonStyle(.borderless)
                }
                Toggle(isOn: Binding(
                    get: { model.format.flatView },
                    set: { _ in model.toggleFlatView() }
                )) { Image(systemName: "list.bullet.indent") }
                .toggleStyle(.button)
                .help("Flat View")
                ColumnChooser(columns: Binding(
                    get: { model.format.columns },
                    set: { newCols in
                        var f = model.format
                        f.columns = newCols
                        model.updateFormat(f)
                    }
                )) {
                    model.rememberCurrentFormat()
                }
                if model.format.viewMode == .thumbnails {
                    Slider(value: Binding(
                        get: { model.format.thumbnailSize },
                        set: { newSize in
                            var f = model.format
                            f.thumbnailSize = newSize
                            model.updateFormat(f)
                        }
                    ), in: 48...200)
                    .frame(width: 100)
                    .help("Thumbnail size")
                }
            }
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(themeManager.listBackground)
            
            Group {
                switch model.format.viewMode {
                case .details, .list: detailsView
                case .icons, .thumbnails: iconsView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(themeManager.listBackground)
            .overlay { if model.isLoading { ProgressView().scaleEffect(1.2) } }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.listBackground)
        .onKeyPress(.space) {
            if let item = model.selectedFileItems.first { onQuickLook(item); return .handled }
            return .ignored
        }
        .onKeyPress(.return) {
            if let item = model.selectedFileItems.first { onOpen(item); return .handled }
            return .ignored
        }
    }
    
    private func handleClick(_ item: FileItem) {
        onActivate()
        let now = Date()
        if lastClickID == item.id && now.timeIntervalSince(lastClickTime) < 0.35 {
            onOpen(item)
            lastClickID = nil
        } else {
            model.select(item)
            lastClickID = item.id
            lastClickTime = now
        }
    }
    
    private var detailsView: some View {
        Table(filteredItems, selection: $model.selectedItems) {
            if visibleColumns.contains(where: { $0.id == "name" }) {
                TableColumn("Name") { item in
                    HStack(spacing: 6) {
                        Image(nsImage: item.icon).resizable().frame(width: 16, height: 16)
                        if model.renamingItem?.id == item.id {
                            TextField("Name", text: $model.renameText, onCommit: { model.commitRename() })
                                .textFieldStyle(.plain).focused($renameFocused)
                                .onAppear { renameFocused = true }
                                .onSubmit { model.commitRename() }
                                .onExitCommand { model.cancelRename() }
                        } else {
                            Text(item.name).lineLimit(1)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { handleClick(item) }
                    .draggable(item.url) {
                        Label(item.name, systemImage: item.isDirectory ? "folder" : "doc")
                            .padding(4)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 4))
                    }
                }
                .width(min: 120, ideal: model.format.width(for: "name"))
            }
            if visibleColumns.contains(where: { $0.id == "size" }) {
                TableColumn("Size") { item in Text(item.formattedSize).foregroundStyle(.secondary) }
                    .width(min: 60, ideal: model.format.width(for: "size"))
            }
            if visibleColumns.contains(where: { $0.id == "dateModified" }) {
                TableColumn("Date Modified") { item in Text(item.formattedDate).foregroundStyle(.secondary) }
                    .width(min: 100, ideal: model.format.width(for: "dateModified"))
            }
            if visibleColumns.contains(where: { $0.id == "kind" }) {
                TableColumn("Kind") { item in Text(item.kind).foregroundStyle(.secondary) }
                    .width(min: 70, ideal: model.format.width(for: "kind"))
            }
            if visibleColumns.contains(where: { $0.id == "dateCreated" }) {
                TableColumn("Created") { item in Text(item.dateCreatedString).foregroundStyle(.secondary) }
                    .width(min: 90, ideal: model.format.width(for: "dateCreated"))
            }
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
        .scrollContentBackground(.hidden)
        .background(themeManager.listBackground)
        .contextMenu {
            if let item = model.selectedFileItems.first {
                Button("Open") { onOpen(item) }
                Button("Quick Look") { onQuickLook(item) }
                Button("Rename") { model.beginRename(item) }
                Divider()
                Button("Select All") { model.selectedItems = Set(filteredItems.map(\.id)) }
                Button("Reveal in Finder") { FileOperations.revealInFinder(model.selectedFileItems) }
                Button("Move to Trash") {
                    try? FileOperations.moveToTrash(model.selectedFileItems)
                    model.navigate(to: model.currentURL)
                }
            }
        }
    }
    
    private var iconsView: some View {
        let size = model.format.viewMode == .thumbnails ? model.format.thumbnailSize : 64
        return ZStack {
            themeManager.listBackground.ignoresSafeArea()
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: size + 40, maximum: size + 80))], spacing: 12) {
                    ForEach(filteredItems) { item in
                        FileIconCell(
                            item: item,
                            size: size,
                            showThumbnail: model.format.viewMode == .thumbnails,
                            isSelected: model.selectedItems.contains(item.id)
                        )
                        .background(GeometryReader { geo in
                            Color.clear.preference(key: CellFrameKey.self, value: [item.id: geo.frame(in: .named("iconsGrid"))])
                        })
                        .onTapGesture { handleClick(item) }
                        .draggable(item.url) {
                            FileIconCell(item: item, size: 40, showThumbnail: false, isSelected: false)
                        }
                        .contextMenu {
                            Button("Open") { onOpen(item) }
                            Button("Quick Look") { onQuickLook(item) }
                            Button("Rename") { model.beginRename(item) }
                            Divider()
                            Button("Select All") { model.selectedItems = Set(filteredItems.map(\.id)) }
                        }
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity)
                .coordinateSpace(name: "iconsGrid")
                .onPreferenceChange(CellFrameKey.self) { cellFrames = $0 }
                .gesture(
                    DragGesture(minimumDistance: 6, coordinateSpace: .named("iconsGrid"))
                        .onChanged { value in
                            onActivate()
                            if dragStart == nil { dragStart = value.startLocation }
                            let start = dragStart ?? value.startLocation
                            let rect = CGRect(
                                x: min(start.x, value.location.x),
                                y: min(start.y, value.location.y),
                                width: abs(value.location.x - start.x),
                                height: abs(value.location.y - start.y)
                            )
                            selectionRect = rect
                            let hits = cellFrames.filter { $0.value.intersects(rect) }.map(\.key)
                            model.selectedItems = Set(hits)
                        }
                        .onEnded { _ in
                            dragStart = nil
                            selectionRect = nil
                        }
                )
            }
            .scrollContentBackground(.hidden)
            
            if let rect = selectionRect {
                Rectangle()
                    .stroke(themeManager.accent, lineWidth: 1)
                    .background(themeManager.accent.opacity(0.12))
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
                    .allowsHitTesting(false)
            }
        }
        .background(themeManager.listBackground)
    }
}

private struct CellFrameKey: PreferenceKey {
    static var defaultValue: [FileItem.ID: CGRect] = [:]
    static func reduce(value: inout [FileItem.ID: CGRect], nextValue: () -> [FileItem.ID: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

struct FileIconCell: View {
    @EnvironmentObject var themeManager: ThemeManager
    let item: FileItem
    let size: CGFloat
    let showThumbnail: Bool
    let isSelected: Bool
    @State private var thumbnail: NSImage?
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                if let thumb = thumbnail {
                    Image(nsImage: thumb)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    Image(nsImage: item.icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: size, height: size)
                }
            }
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isSelected ? themeManager.accent.opacity(0.3) : Color.clear)
            )
            
            Text(item.name)
                .font(.system(size: 11))
                .foregroundStyle(themeManager.theme.textColor.color)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: size + 16)
            
            if !item.isDirectory {
                Text(item.formattedSize)
                    .font(.system(size: 9))
                    .foregroundStyle(themeManager.theme.secondaryTextColor.color)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? themeManager.accent.opacity(0.15) : Color.clear)
        )
        .task(id: item.url) {
            if showThumbnail && item.isImage {
                thumbnail = await ThumbnailCache.shared.thumbnail(for: item.url, size: size * 2)
            }
        }
    }
}
