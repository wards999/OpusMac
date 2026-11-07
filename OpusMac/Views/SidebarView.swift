import SwiftUI

struct SidebarView: View {
    @Binding var selectedURL: URL?
    
    private let favorites: [(String, URL)] = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return [
            ("Home", home),
            ("Desktop", home.appendingPathComponent("Desktop")),
            ("Documents", home.appendingPathComponent("Documents")),
            ("Downloads", home.appendingPathComponent("Downloads")),
            ("Pictures", home.appendingPathComponent("Pictures")),
            ("Music", home.appendingPathComponent("Music"))
        ]
    }()
    
    var body: some View {
        List {
            Section("Favorites") {
                ForEach(favorites, id: \.1) { name, url in
                    Button { selectedURL = url } label: {
                        Label(name, systemImage: iconName(for: name))
                    }
                    .buttonStyle(.plain)
                }
            }
            Section("Volumes") {
                ForEach(volumes, id: \.self) { url in
                    Button { selectedURL = url } label: {
                        Label(url.lastPathComponent, systemImage: "externaldrive")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 180, idealWidth: 200, maxWidth: 260)
    }
    
    private var volumes: [URL] {
        (FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: nil) ?? [])
            .filter { $0.path.hasPrefix("/Volumes") || $0.path == "/" }
    }
    
    private func iconName(for name: String) -> String {
        switch name {
        case "Home": return "house"
        case "Desktop": return "desktopcomputer"
        case "Documents": return "doc"
        case "Downloads": return "arrow.down.circle"
        case "Pictures": return "photo"
        case "Music": return "music.note"
        default: return "folder"
        }
    }
}
