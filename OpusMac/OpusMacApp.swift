import SwiftUI

@main
struct OpusMacApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 900, minHeight: 600)
                .preferredColorScheme(themeManager.preferredColorScheme())
                .tint(themeManager.accent)
                .environmentObject(themeManager)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) { }
            
            CommandMenu("Go") {
                Button("Back") { NotificationCenter.default.post(name: .goBack, object: nil) }
                    .keyboardShortcut("[", modifiers: .command)
                Button("Forward") { NotificationCenter.default.post(name: .goForward, object: nil) }
                    .keyboardShortcut("]", modifiers: .command)
                Button("Enclosing Folder") { NotificationCenter.default.post(name: .goUp, object: nil) }
                    .keyboardShortcut(.upArrow, modifiers: .command)
            }
            
            CommandMenu("View") {
                Button("Remember View for this Folder") {
                    NotificationCenter.default.post(name: .rememberFormat, object: nil)
                }
                Button("Clear Format for this Folder") {
                    NotificationCenter.default.post(name: .clearFormat, object: nil)
                }
                
                Divider()
                
                Button("Theme…") {
                    NotificationCenter.default.post(name: .openThemeSettings, object: nil)
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
            }
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
}
