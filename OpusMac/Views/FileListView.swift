import SwiftUI
import UniformTypeIdentifiers

struct FileListView: View {
    @ObservedObject var model: PaneModel
    let isActive: Bool
    var onActivate: () -> Void
    var onOpen: (FileItem) -> Void
    var onQuickLook: (FileItem) -> Void
    @State private var filterText = ""
    @FocusState private var renameFocused: Bool
    
    private var filteredItems: [FileItem] {
        guard !filterText.isEmpty else { return model.items }
        return model.items.filter { $0.name.localizedCaseInsensitiveContains(filterText) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Filter\u2026", text: $filterText).textFieldStyle(.plain)
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
            }
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            
            Group {
                switch model.format.viewMode {
                case .details, .list: detailsView
                case .icons, .thumbnails: iconsView
                }
            }
            .overlay { if model.isLoading { ProgressView().scaleEffect(1.2) } }
        }
        .onTapGesture { onActivate() }
        .onKeyPress(.space) {
            if let item = model.selectedFileItems.first { onQuickLook(item); return .handled }
            return .ignored
        }
    }
    
    private var detailsView: some View {
        Table(filteredItems, selection: $model.selectedItems) {
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
                            .onTapGesture(count: 2) { onOpen(item) }
                    }
                }
                .contentShape(Rectangle())
                .draggable(item.url) {
                    Label(item.name, systemImage: item.isDirectory ? "folder" : "doc")
                        .padding(6).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
                }
            }.width(min: 180, ideal: 260)
            TableColumn("Size") { item in Text(item.formattedSize).foregroundStyle(.secondary) }.width(min: 70, ideal: 90)
            TableColumn("Date Modified") { item in Text(item.formattedDate).foregroundStyle(.secondary) }.width(min: 120, ideal: 150)
            TableColumn("Kind") { item in Text(item.kind).foregroundStyle(.secondary) }.width(min: 80, ideal: 120)
            TableColumn("Created") { item in Text(item.dateCreatedString).foregroundStyle(.secondary) }.width(min: 100, ideal: 140)
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
        .onChange(of: model.selectedItems) { _, _ in onActivate() }
        .contextMenu {
            if let item = model.selectedFileItems.first {
                Button("Open") { onOpen(item) }
                Button("Quick Look") { onQuickLook(item) }
                Button("Rename") { model.beginRename(item) }
                Divider()
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
        return ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: size + 40, maximum: size + 80))], spacing: 16) {
                ForEach(filteredItems) { item in
                    FileIconCell(item: item, size: size, isSelected: model.selectedItems.contains(item.id))
                        .onTapGesture(count: 2) { onOpen(item) }
                        .onTapGesture {
                            onActivate()
                            if NSEvent.modifierFlags.contains(.command) { model.toggleSelection(item) }
                            else { model.select(item) }
                        }
                        .draggable(item.url) { FileIconCell(item: item, size: 48, isSelected: false).opacity(0.9) }
                        .contextMenu {
                            Button("Open") { onOpen(item) }
                            Button("Quick Look") { onQuickLook(item) }
                            Button("Rename") { model.beginRename(item) }
                        }
                }
            }.padding()
        }
    }
}

struct FileIconCell: View {
    let item: FileItem
    let size: CGFloat
    let isSelected: Bool
    var body: some View {
        VStack(spacing: 6) {
            Image(nsImage: item.icon).resizable().aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .background(RoundedRectangle(cornerRadius: 6).fill(isSelected ? Color.accentColor.opacity(0.2) : Color.clear))
            Text(item.name).font(.caption).lineLimit(2).multilineTextAlignment(.center).frame(width: size + 20)
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 8).fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear))
    }
}
