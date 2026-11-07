import SwiftUI

struct FolderTreeView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var selectedURL: URL?
    var onSelect: (URL) -> Void
    @State private var rootNodes: [TreeNode] = []
    @State private var expanded: Set<URL> = []
    
    var body: some View {
        List(selection: Binding(
            get: { selectedURL },
            set: { newValue in
                selectedURL = newValue
                if let url = newValue { onSelect(url) }
            }
        )) {
            ForEach(rootNodes) { node in
                TreeNodeView(node: node, expanded: $expanded, selectedURL: $selectedURL, onSelect: onSelect)
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(themeManager.paneBackground)
        .onAppear { loadRoots() }
    }
    
    private func loadRoots() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let volumes = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: nil) ?? []
        var nodes: [TreeNode] = [TreeNode(url: home, name: "Home", isDirectory: true)]
        for name in ["Desktop", "Documents", "Downloads", "Pictures", "Music"] {
            let url = home.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: url.path) {
                nodes.append(TreeNode(url: url, name: name, isDirectory: true))
            }
        }
        for vol in volumes where vol.path != "/" {
            nodes.append(TreeNode(url: vol, name: vol.lastPathComponent, isDirectory: true))
        }
        rootNodes = nodes
        expanded.insert(home)
    }
}

struct TreeNode: Identifiable, Hashable {
    let id: URL
    let url: URL
    let name: String
    let isDirectory: Bool
    init(url: URL, name: String, isDirectory: Bool) {
        self.id = url; self.url = url; self.name = name; self.isDirectory = isDirectory
    }
    func loadChildren() -> [TreeNode] {
        guard isDirectory else { return [] }
        guard let urls = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else { return [] }
        return urls.compactMap { childURL -> TreeNode? in
            let values = try? childURL.resourceValues(forKeys: [.isDirectoryKey])
            guard let isDir = values?.isDirectory, isDir else { return nil }
            return TreeNode(url: childURL, name: childURL.lastPathComponent, isDirectory: true)
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}

struct TreeNodeView: View {
    let node: TreeNode
    @Binding var expanded: Set<URL>
    @Binding var selectedURL: URL?
    var onSelect: (URL) -> Void
    @State private var children: [TreeNode] = []
    @State private var loaded = false
    
    var body: some View {
        DisclosureGroup(isExpanded: Binding(
            get: { expanded.contains(node.url) },
            set: { isExp in
                if isExp {
                    expanded.insert(node.url)
                    if !loaded { children = node.loadChildren(); loaded = true }
                } else { expanded.remove(node.url) }
            }
        )) {
            ForEach(children) { child in
                TreeNodeView(node: child, expanded: $expanded, selectedURL: $selectedURL, onSelect: onSelect)
            }
        } label: {
            Label(node.name, systemImage: "folder")
                .onTapGesture { selectedURL = node.url; onSelect(node.url) }
        }
    }
}
