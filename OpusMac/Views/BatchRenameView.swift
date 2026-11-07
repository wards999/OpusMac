import SwiftUI

struct BatchRenameView: View {
    let items: [FileItem]
    var onRename: ([URL: String]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var mode: RenameMode = .replace
    @State private var findText = ""
    @State private var replaceText = ""
    @State private var prefix = ""
    @State private var suffix = ""
    @State private var startNumber = 1
    @State private var numberPadding = 2
    
    enum RenameMode: String, CaseIterable, Identifiable {
        case replace = "Find & Replace"
        case prefixSuffix = "Prefix / Suffix"
        case number = "Number Sequentially"
        var id: String { rawValue }
    }
    
    private var preview: [(original: String, newName: String)] {
        items.map { item in (item.name, computeNewName(for: item.name)) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Form {
                Picker("Mode", selection: $mode) {
                    ForEach(RenameMode.allCases) { m in Text(m.rawValue).tag(m) }
                }.pickerStyle(.segmented)
                switch mode {
                case .replace:
                    TextField("Find", text: $findText)
                    TextField("Replace with", text: $replaceText)
                case .prefixSuffix:
                    TextField("Prefix", text: $prefix)
                    TextField("Suffix", text: $suffix)
                case .number:
                    TextField("Prefix", text: $prefix)
                    Stepper("Start at: \(startNumber)", value: $startNumber, in: 0...9999)
                    Stepper("Padding: \(numberPadding)", value: $numberPadding, in: 1...6)
                }
            }.formStyle(.grouped).padding()
            Divider()
            Table(preview, columns: {
                TableColumn("Original") { row in Text(row.original).lineLimit(1) }
                TableColumn("New Name") { row in
                    Text(row.newName).lineLimit(1)
                        .foregroundStyle(row.newName != row.original ? .primary : .secondary)
                }
            }).frame(minHeight: 200)
            Divider()
            HStack {
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                Spacer()
                Button("Rename \(items.count) items") {
                    var mapping: [URL: String] = [:]
                    for item in items {
                        let newName = computeNewName(for: item.name)
                        if newName != item.name { mapping[item.url] = newName }
                    }
                    onRename(mapping)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(preview.allSatisfy { $0.original == $0.newName })
            }.padding()
        }
        .frame(width: 520, height: 480)
        .navigationTitle("Batch Rename")
    }
    
    private func computeNewName(for name: String) -> String {
        let base = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension
        let extensionPart = ext.isEmpty ? "" : ".\(ext)"
        switch mode {
        case .replace:
            guard !findText.isEmpty else { return name }
            return base.replacingOccurrences(of: findText, with: replaceText) + extensionPart
        case .prefixSuffix:
            return prefix + base + suffix + extensionPart
        case .number:
            if let idx = items.firstIndex(where: { $0.name == name }) {
                let number = String(format: "%0\(numberPadding)d", startNumber + idx)
                return prefix + number + extensionPart
            }
            return name
        }
    }
}
