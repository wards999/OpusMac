import SwiftUI
import AppKit

enum ThemeMode: String, CaseIterable, Identifiable, Codable {
    case system, light, dark, custom
    case dracula, vscodeDark, vscodeLight, solarizedLight
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        case .custom: return "Custom"
        case .dracula: return "Dracula"
        case .vscodeDark: return "VS Code Dark"
        case .vscodeLight: return "VS Code Light"
        case .solarizedLight: return "Solarized Light"
        }
    }
    var isDark: Bool {
        switch self {
        case .light, .vscodeLight, .solarizedLight: return false
        case .system: return false
        default: return true
        }
    }
}

struct AppTheme: Codable, Equatable {
    var mode: ThemeMode = .dark
    var accentColor: CodableColor = CodableColor(Color(red: 0.25, green: 0.52, blue: 0.95))
    var paneBackground: CodableColor = CodableColor(Color(red: 0.13, green: 0.13, blue: 0.14))
    var listBackground: CodableColor = CodableColor(Color(red: 0.11, green: 0.11, blue: 0.12))
    var selectionColor: CodableColor = CodableColor(Color(red: 0.25, green: 0.52, blue: 0.95))
    var textColor: CodableColor = CodableColor(Color.white)
    var secondaryTextColor: CodableColor = CodableColor(Color.gray)
    static let `default` = AppTheme()
    
    static func preset(_ mode: ThemeMode) -> AppTheme {
        var t = AppTheme()
        t.mode = mode
        switch mode {
        case .dracula:
            t.accentColor = CodableColor(Color(red: 0.74, green: 0.58, blue: 0.98))
            t.paneBackground = CodableColor(Color(red: 0.16, green: 0.16, blue: 0.21))
            t.listBackground = CodableColor(Color(red: 0.12, green: 0.12, blue: 0.16))
            t.selectionColor = CodableColor(Color(red: 0.74, green: 0.58, blue: 0.98))
            t.textColor = CodableColor(Color(red: 0.97, green: 0.97, blue: 0.95))
            t.secondaryTextColor = CodableColor(Color(red: 0.38, green: 0.44, blue: 0.54))
        case .vscodeDark:
            t.accentColor = CodableColor(Color(red: 0.0, green: 0.48, blue: 0.85))
            t.paneBackground = CodableColor(Color(red: 0.12, green: 0.12, blue: 0.12))
            t.listBackground = CodableColor(Color(red: 0.10, green: 0.10, blue: 0.10))
            t.selectionColor = CodableColor(Color(red: 0.0, green: 0.48, blue: 0.85))
            t.textColor = CodableColor(Color(red: 0.83, green: 0.83, blue: 0.83))
            t.secondaryTextColor = CodableColor(Color(red: 0.55, green: 0.55, blue: 0.55))
        case .vscodeLight:
            t.accentColor = CodableColor(Color(red: 0.0, green: 0.48, blue: 0.85))
            t.paneBackground = CodableColor(Color(red: 0.95, green: 0.95, blue: 0.95))
            t.listBackground = CodableColor(Color.white)
            t.selectionColor = CodableColor(Color(red: 0.0, green: 0.48, blue: 0.85))
            t.textColor = CodableColor(Color(red: 0.13, green: 0.13, blue: 0.13))
            t.secondaryTextColor = CodableColor(Color(red: 0.4, green: 0.4, blue: 0.4))
        case .solarizedLight:
            t.accentColor = CodableColor(Color(red: 0.15, green: 0.55, blue: 0.82))
            t.paneBackground = CodableColor(Color(red: 0.93, green: 0.91, blue: 0.84))
            t.listBackground = CodableColor(Color(red: 0.99, green: 0.96, blue: 0.89))
            t.selectionColor = CodableColor(Color(red: 0.15, green: 0.55, blue: 0.82))
            t.textColor = CodableColor(Color(red: 0.4, green: 0.48, blue: 0.51))
            t.secondaryTextColor = CodableColor(Color(red: 0.58, green: 0.63, blue: 0.63))
        case .light:
            t.accentColor = CodableColor(Color(red: 0.0, green: 0.48, blue: 0.85))
            t.paneBackground = CodableColor(Color(red: 0.95, green: 0.95, blue: 0.95))
            t.listBackground = CodableColor(Color.white)
            t.selectionColor = CodableColor(Color(red: 0.0, green: 0.48, blue: 0.85))
            t.textColor = CodableColor(Color.black)
            t.secondaryTextColor = CodableColor(Color.gray)
        default:
            break
        }
        return t
    }
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
        case .light, .vscodeLight, .solarizedLight: return .light
        default: return .dark
        }
    }
    func applyPreset(_ mode: ThemeMode) {
        theme = AppTheme.preset(mode)
    }
}
