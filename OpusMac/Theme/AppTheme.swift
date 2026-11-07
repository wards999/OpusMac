import SwiftUI
import AppKit

enum ThemeMode: String, CaseIterable, Identifiable, Codable {
    case system, light, dark, custom
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        case .custom: return "Custom"
        }
    }
}

struct AppTheme: Codable, Equatable {
    var mode: ThemeMode = .system
    var accentColor: CodableColor = CodableColor(.accentColor)
    var paneBackground: CodableColor = CodableColor(NSColor.windowBackgroundColor)
    var listBackground: CodableColor = CodableColor(NSColor.controlBackgroundColor)
    var selectionColor: CodableColor = CodableColor(.accentColor)
    var textColor: CodableColor = CodableColor(NSColor.labelColor)
    var secondaryTextColor: CodableColor = CodableColor(NSColor.secondaryLabelColor)
    static let `default` = AppTheme()
}

struct CodableColor: Codable, Equatable {
    var red: Double; var green: Double; var blue: Double; var opacity: Double
    init(_ color: Color) {
        let nsColor = NSColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        nsColor.usingColorSpace(.sRGB)?.getRed(&r, green: &g, blue: &b, alpha: &a)
        red = Double(r); green = Double(g); blue = Double(b); opacity = Double(a)
    }
    init(_ nsColor: NSColor) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        nsColor.usingColorSpace(.sRGB)?.getRed(&r, green: &g, blue: &b, alpha: &a)
        red = Double(r); green = Double(g); blue = Double(b); opacity = Double(a)
    }
    var color: Color { Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity) }
    var nsColor: NSColor { NSColor(srgbRed: red, green: green, blue: blue, alpha: opacity) }
}

@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    @Published var theme: AppTheme { didSet { save() } }
    private let fileURL: URL
    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("OpusMac", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("Theme.json")
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode(AppTheme.self, from: data) {
            theme = decoded
        } else { theme = .default }
    }
    private func save() {
        guard let data = try? JSONEncoder().encode(theme) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
    var accent: Color { theme.accentColor.color }
    var paneBackground: Color { theme.paneBackground.color }
    var listBackground: Color { theme.listBackground.color }
    var selection: Color { theme.selectionColor.color }
    func preferredColorScheme() -> ColorScheme? {
        switch theme.mode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        case .custom: return nil
        }
    }
}
