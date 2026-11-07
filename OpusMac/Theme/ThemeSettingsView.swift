import SwiftUI

struct ThemeSettingsView: View {
    @ObservedObject var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: $themeManager.theme.mode) {
                    ForEach(ThemeMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
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
        .frame(width: 380, height: 340)
        .navigationTitle("Theme")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}
