import SwiftUI

struct TabBarView: View {
    @EnvironmentObject var themeManager: ThemeManager
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
                .padding(.leading, 2)
            }
            Spacer(minLength: 2)
            Button { manager.addTab() } label: {
                Image(systemName: "plus")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(themeManager.theme.secondaryTextColor.color)
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.borderless)
            .help("New Tab")
            .padding(.trailing, 4)
        }
        .frame(height: 24)
        .background(themeManager.paneBackground)
    }
}

struct TabItemView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var tab: TabModel
    let isSelected: Bool
    let isActivePane: Bool
    var onSelect: () -> Void
    var onClose: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "folder.fill")
                .font(.system(size: 8))
                .foregroundStyle(isSelected ? themeManager.accent : themeManager.theme.secondaryTextColor.color)
            Text(tab.title)
                .font(.system(size: 11, weight: isSelected ? .medium : .regular))
                .foregroundStyle(themeManager.theme.textColor.color)
                .lineLimit(1)
            if isSelected || isHovering {
                Button { onClose() } label: {
                    Image(systemName: "xmark").font(.system(size: 7, weight: .bold))
                }
                .buttonStyle(.borderless)
                .foregroundStyle(themeManager.theme.secondaryTextColor.color)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(backgroundColor)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { isHovering = $0 }
        .contextMenu { Button("Close Tab") { onClose() } }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return isActivePane ? themeManager.accent.opacity(0.25) : themeManager.theme.textColor.color.opacity(0.08)
        }
        return isHovering ? themeManager.theme.textColor.color.opacity(0.05) : Color.clear
    }
}
