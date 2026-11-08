import SwiftUI
import AppKit

@main
struct OpusMacApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1000, minHeight: 650)
                .preferredColorScheme(themeManager.preferredColorScheme())
                .tint(themeManager.accent)
                .environmentObject(themeManager)
                .background(WindowAppearanceApplier(themeManager: themeManager))
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .defaultSize(width: 1280, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) { }
            
            CommandMenu("File") {
                Button("New Folder") {
                    NotificationCenter.default.post(name: .newFolder, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
                
                Divider()
                
                Button("Copy to Other Pane") {
                    NotificationCenter.default.post(name: .copyToOtherPane, object: nil)
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                
                Button("Move to Other Pane") {
                    NotificationCenter.default.post(name: .moveToOtherPane, object: nil)
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])
            }
            
            CommandMenu("Go") {
                Button("Back") {
                    NotificationCenter.default.post(name: .goBack, object: nil)
                }
                .keyboardShortcut("[", modifiers: .command)
                
                Button("Forward") {
                    NotificationCenter.default.post(name: .goForward, object: nil)
                }
                .keyboardShortcut("]", modifiers: .command)
                
                Button("Enclosing Folder") {
                    NotificationCenter.default.post(name: .goUp, object: nil)
                }
                .keyboardShortcut(.upArrow, modifiers: .command)
                
                Divider()
                
                Button("Swap Panes") {
                    NotificationCenter.default.post(name: .swapPanes, object: nil)
                }
                .keyboardShortcut("u", modifiers: .command)
            }
            
            CommandMenu("View") {
                Button("Remember View for this Folder") {
                    NotificationCenter.default.post(name: .rememberFormat, object: nil)
                }
                Button("Clear Format for this Folder") {
                    NotificationCenter.default.post(name: .clearFormat, object: nil)
                }
                
                Divider()
                
                Button("Synchronize\u{2026}") {
                    NotificationCenter.default.post(name: .openSynchronize, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                
                Button("Path-Pattern Formats\u{2026}") {
                    NotificationCenter.default.post(name: .openFormatPatterns, object: nil)
                }
            }
            
            CommandGroup(replacing: .appSettings) {
                Button("Settings\u{2026}") {
                    NotificationCenter.default.post(name: .openSettings, object: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}

private struct WindowAppearanceApplier: NSViewRepresentable {
    let themeManager: ThemeManager
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            apply(to: view)
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            apply(to: nsView)
        }
    }
    private func apply(to view: NSView) {
        guard let window = view.window else { return }
        switch themeManager.theme.mode {
        case .dark, .custom:
            window.appearance = NSAppearance(named: .darkAqua)
            NSApp.appearance = NSAppearance(named: .darkAqua)
        case .light:
            window.appearance = NSAppearance(named: .aqua)
            NSApp.appearance = NSAppearance(named: .aqua)
        case .system:
            window.appearance = nil
            NSApp.appearance = nil
        }
    }
}

extension Notification.Name {
    static let goBack = Notification.Name("goBack")
    static let goForward = Notification.Name("goForward")
    static let goUp = Notification.Name("goUp")
    static let rememberFormat = Notification.Name("rememberFormat")
    static let clearFormat = Notification.Name("clearFormat")
    static let openThemeSettings = Notification.Name("openThemeSettings")
    static let copyToOtherPane = Notification.Name("copyToOtherPane")
    static let moveToOtherPane = Notification.Name("moveToOtherPane")
    static let newFolder = Notification.Name("newFolder")
    static let swapPanes = Notification.Name("swapPanes")
    static let openSynchronize = Notification.Name("openSynchronize")
    static let openFormatPatterns = Notification.Name("openFormatPatterns")
    static let openSettings = Notification.Name("openSettings")
}
