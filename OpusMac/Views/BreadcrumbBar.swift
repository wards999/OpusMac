import SwiftUI

struct BreadcrumbBar: View {
    @EnvironmentObject var themeManager: ThemeManager
    let url: URL
    var onNavigate: (URL) -> Void
    
    @State private var isEditing = false
    @State private var editText = ""
    @FocusState private var pathFocused: Bool
    
    private var components: [(name: String, url: URL)] {
        var result: [(String, URL)] = []
        var current = url.standardizedFileURL
        let root = URL(fileURLWithPath: "/")
        while current.path != "/" && !current.path.isEmpty {
            result.insert((current.lastPathComponent, current), at: 0)
            let parent = current.deletingLastPathComponent()
            if parent.path == current.path { break }
            current = parent
        }
        result.insert(("Macintosh HD", root), at: 0)
        return result
    }
    
    var body: some View {
        HStack(spacing: 2) {
            if isEditing {
                TextField("Path", text: $editText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(themeManager.theme.textColor.color)
                    .focused($pathFocused)
                    .onSubmit { commitEdit() }
                    .onExitCommand { isEditing = false }
                    .onAppear {
                        editText = url.path
                        pathFocused = true
                    }
                Button("Go") { commitEdit() }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                Button("Cancel") { isEditing = false }
                    .buttonStyle(.borderless)
                    .controlSize(.mini)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(Array(components.enumerated()), id: \.offset) { index, item in
                            if index > 0 {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 7, weight: .semibold))
                                    .foregroundStyle(themeManager.theme.secondaryTextColor.color)
                                    .padding(.horizontal, 1)
                            }
                            Button { onNavigate(item.url) } label: {
                                Text(item.name)
                                    .font(.system(size: 11, weight: index == components.count - 1 ? .semibold : .regular))
                                    .foregroundStyle(themeManager.theme.textColor.color)
                                    .lineLimit(1)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(index == components.count - 1 ? themeManager.accent.opacity(0.2) : Color.clear)
                                    )
                            }
                            .buttonStyle(.plain)
                            .help(item.url.path)
                        }
                    }
                }
                Button { isEditing = true } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 9))
                        .foregroundStyle(themeManager.theme.secondaryTextColor.color)
                }
                .buttonStyle(.borderless)
                .help("Edit path")
            }
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 1)
    }
    
    private func commitEdit() {
        var path = editText.trimmingCharacters(in: .whitespacesAndNewlines)
        if path.hasPrefix("~") {
            path = NSString(string: path).expandingTildeInPath
        }
        let target = URL(fileURLWithPath: path)
        if FileManager.default.fileExists(atPath: target.path) {
            onNavigate(target)
            isEditing = false
        } else {
            NSSound.beep()
        }
    }
}
