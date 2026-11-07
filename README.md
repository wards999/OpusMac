# OpusMac

A dual-pane power-user file manager for macOS, inspired by Directory Opus.

**Repo:** https://github.com/wards999/OpusMac

## Features

### Dual-pane core
- Dual resizable panes with **tabs**
- **Drag = Move**, **⌥-drag = Copy**
- **Copy / Move to other pane** (⌘⇧C / ⌘⇧M)
- Per-folder view memory + **path-pattern formats** (e.g. `~/Pictures` → Icons)
- Folder Tree + quick favorites
- Source → Destination indicator

### Navigation & views
- Tabs, Back / Forward / Up
- Details / Icons / List / Thumbnails
- **Flat View** (recursive)
- Find-as-you-type filter
- Columns: Name, Size, Date Modified, Kind, Created
- **Inline Rename**
- Viewer pane + Space Quick Look

### Archives
- Basic **ZIP browsing**

### Synchronize
- Compare left vs right folder
- Show missing / newer / size-different files
- Selective one-way sync

### File operations
- New Folder, Trash, Batch Rename
- Transfer progress + conflict dialog

### Polish
- Themes, status bar, keyboard-centric menus

## Build

```bash
brew install xcodegen
xcodegen generate
open OpusMac.xcodeproj
```

## License

MIT
