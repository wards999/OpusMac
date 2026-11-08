import SwiftUI

struct ThemeSettingsView: View {
    @ObservedObject var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section("Theme") {
                Picker("Preset", selection: Binding(
                    get: { themeManager.theme.mode },
                    set: { themeManager.applyPreset($0) }
                )) {
                    ForEach(ThemeMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
            }
            Section("Colors") {
                ColorPicker("Accent Color", selection: Binding(
                    get: { themeManager.theme.accentColor.color },
                    set: { themeManager.theme.accentColor = CodableColor($0) }
                ))
                ColorPicker("Pane Background", selection: Binding(
                    get: { themeManager.theme.paneBackground.color },
                    set: { themeManager.theme.paneBackground = CodableColor($0) }
                ))
                ColorPicker("List Background", selection: Binding(
                    get: { themeManager.theme.listBackground.color },
                    set: { themeManager.theme.listBackground = CodableColor($0) }
                ))
                ColorPicker("Selection Color", selection: Binding(
                    get: { themeManager.theme.selectionColor.color },
                    set: { themeManager.theme.selectionColor = CodableColor($0) }
                ))
            }
            Section {
                Button("Reset to Defaults") { themeManager.theme = .default }
                    .foregroundStyle(.red)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 420)
        .navigationTitle("Theme")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}
