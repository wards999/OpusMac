import SwiftUI

struct FormatPatternsView: View {
    @State private var rules: [FormatStore.PatternRule] = []
    @State private var newPattern = ""
    @State private var selectedViewMode: ViewMode = .icons
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Add Path Pattern") {
                    TextField("Path or pattern (e.g. ~/Pictures or **/Downloads)", text: $newPattern)
                    Picker("Default View", selection: $selectedViewMode) {
                        ForEach(ViewMode.allCases) { mode in Text(mode.displayName).tag(mode) }
                    }
                    Button("Add Rule") { addRule() }
                        .disabled(newPattern.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                Section("Active Rules") {
                    if rules.isEmpty {
                        Text("No pattern rules yet. Exact per-folder formats still work.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(rules) { rule in
                            HStack {
                                Toggle("", isOn: Binding(
                                    get: { rule.enabled },
                                    set: { enabled in
                                        var updated = rule
                                        updated.enabled = enabled
                                        Task {
                                            await FormatStore.shared.updatePatternRule(updated)
                                            await reload()
                                        }
                                    }
                                )).labelsHidden()
                                VStack(alignment: .leading) {
                                    Text(rule.pattern).font(.system(.body, design: .monospaced))
                                    Text(rule.format.viewMode.displayName).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button(role: .destructive) {
                                    Task {
                                        await FormatStore.shared.removePatternRule(id: rule.id)
                                        await reload()
                                    }
                                } label: { Image(systemName: "trash") }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }
            }.formStyle(.grouped)
            HStack {
                Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
            }.padding()
        }
        .frame(width: 480, height: 420)
        .navigationTitle("Path-Pattern Formats")
        .task { await reload() }
    }
    
    private func addRule() {
        let pattern = newPattern.trimmingCharacters(in: .whitespaces)
        guard !pattern.isEmpty else { return }
        var format = FolderFormat.default
        format.viewMode = selectedViewMode
        let rule = FormatStore.PatternRule(pattern: pattern, format: format)
        Task {
            await FormatStore.shared.addPatternRule(rule)
            newPattern = ""
            await reload()
        }
    }
    
    private func reload() async {
        rules = await FormatStore.shared.allPatternRules()
    }
}
