# OpusMac

A dual-pane power-user file manager for macOS, inspired by Directory Opus.

**Repository:** https://github.com/wards999/OpusMac

## Features

- **Dual-pane layout** (resizable)
- **Per-folder view memory** ("Folder Formats") – remembers view mode, columns, sort order, thumbnail size, hidden files per folder
- Independent navigation history (Back / Forward / Up) per pane
- Sortable columns + multiple view modes (Details, Icons, List, Thumbnails)
- **Drag between panes = Move**, **Option-drag = Copy** (with visual feedback)
- Themes (System / Light / Dark / Custom colours)
- Sidebar with Favorites + Volumes
- Folder Tree foundation
- Batch Rename foundation
- No scripting, no FTP

## Requirements

- macOS 14.0+
- Xcode 15+ (for local development)

## Getting Started

### Option A – Open in Xcode

1. Clone the repo
2. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
3. Run `xcodegen generate`
4. Open `OpusMac.xcodeproj` and Build & Run (⌘R)

### Option B – Direct

Create a new macOS App project named `OpusMac`, then drag the contents of the `OpusMac/` folder into it.

## Automated Builds & Releases

Every push to `main` triggers a GitHub Actions workflow that:

1. Generates the Xcode project with XcodeGen
2. Builds a Release archive
3. Creates a DMG
4. Uploads the DMG as a workflow artifact
5. Creates a pre-release on GitHub with the DMG attached

You can also trigger it manually from the **Actions** tab.

## License

MIT
