import SwiftUI

struct TabBarView: View {
    @ObservedObject var manager: PaneTabManager
    var isActive: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 1) {
                    ForEach(manager.tabs) { tab in
                        TabItemView(
                            tab: tab,
                            isSelected: tab.id == manager.selectedTabID,
                            isActivePane: isActive,
                            onSelect: { manager.selectTab(tab.id) },
                            onClose: { manager.closeTab(tab.id) }
                        )
                    }
                }
                .padding(.leading, 4)
            }
            Spacer(minLength: 4)
            Button { manager.addTab() } label: {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .semibold))
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.borderless)
            .help("New Tab")
            .padding(.trailing, 6)
        }
        .frame(height: 30)
        .background(
            LinearGradient(
                colors: [Color(nsColor: .windowBackgroundColor), Color(nsColor: .controlBackgroundColor)],
                startPoint: .top, endPoint: .bottom
            )
        )
    }
}

struct TabItemView: View {
    @ObservedObject var tab: TabModel
    let isSelected: Bool
    let isActivePane: Bool
    var onSelect: () -> Void
    var onClose: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "folder.fill")
                .font(.system(size: 9))
                .foregroundStyle(isSelected && isActivePane ? Color.accentColor : .secondary)
            Text(tab.title)
                .font(.system(size: 11, weight: isSelected ? .medium : .regular))
                .lineLimit(1)
            if isSelected || isHovering {
                Button { onClose() } label: {
                    Image(systemName: "xmark").font(.system(size: 8, weight: .bold))
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(RoundedRectangle(cornerRadius: 5).fill(backgroundColor))
        .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(borderColor, lineWidth: isSelected ? 1 : 0))
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { isHovering = $0 }
        .contextMenu { Button("Close Tab") { onClose() } }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return isActivePane ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.12)
        }
        return isHovering ? Color.secondary.opacity(0.08) : Color.clear
    }
    
    private var borderColor: Color {
        isSelected && isActivePane ? Color.accentColor.opacity(0.45) : Color.clear
    }
}
