import Foundation

actor FormatStore {
    static let shared = FormatStore()
    
    private var exactFormats: [String: FolderFormat] = [:]
    private var patternRules: [PatternRule] = []
    private let fileURL: URL
    private let patternsURL: URL
    
    struct PatternRule: Codable, Identifiable, Equatable {
        var id: UUID = UUID()
        var pattern: String
        var format: FolderFormat
        var enabled: Bool = true
    }
    
    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("OpusMac", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("FolderFormats.json")
        patternsURL = dir.appendingPathComponent("FormatPatterns.json")
        Task { await load() }
    }
    
    func format(for path: String) -> FolderFormat {
        let normalized = normalize(path)
        for rule in patternRules where rule.enabled {
            if matches(pattern: rule.pattern, path: normalized) {
                return rule.format
            }
        }
        if let exact = exactFormats[normalized] {
            return exact
        }
        return .default
    }
    
    func save(_ format: FolderFormat, for path: String) {
        exactFormats[normalize(path)] = format
        Task { await persistExact() }
    }
    
    func clear(for path: String) {
        exactFormats.removeValue(forKey: normalize(path))
        Task { await persistExact() }
    }
    
    func allPatternRules() -> [PatternRule] { patternRules }
    
    func addPatternRule(_ rule: PatternRule) {
        patternRules.append(rule)
        Task { await persistPatterns() }
    }
    
    func updatePatternRule(_ rule: PatternRule) {
        if let idx = patternRules.firstIndex(where: { $0.id == rule.id }) {
            patternRules[idx] = rule
            Task { await persistPatterns() }
        }
    }
    
    func removePatternRule(id: UUID) {
        patternRules.removeAll { $0.id == id }
        Task { await persistPatterns() }
    }
    
    private func matches(pattern: String, path: String) -> Bool {
        var pat = pattern
        if pat.hasPrefix("~/") || pat == "~" {
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            pat = pat == "~" ? home : home + String(pat.dropFirst())
        }
        pat = normalize(pat)
        if path == pat || path.hasPrefix(pat + "/") { return true }
        if pat.hasPrefix("**/") {
            let component = String(pat.dropFirst(3))
            return path.components(separatedBy: "/").contains(component)
        }
        return false
    }
    
    private func normalize(_ path: String) -> String {
        (path as NSString).standardizingPath
    }
    
    private func load() async {
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([String: FolderFormat].self, from: data) {
            exactFormats = decoded
        }
        if let data = try? Data(contentsOf: patternsURL),
           let decoded = try? JSONDecoder().decode([PatternRule].self, from: data) {
            patternRules = decoded
        }
    }
    
    private func persistExact() async {
        guard let data = try? JSONEncoder().encode(exactFormats) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
    
    private func persistPatterns() async {
        guard let data = try? JSONEncoder().encode(patternRules) else { return }
        try? data.write(to: patternsURL, options: .atomic)
    }
}
