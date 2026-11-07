import SwiftUI

struct ColumnChooser: View {
    @Binding var columns: [ColumnConfig]
    var onChange: () -> Void
    
    var body: some View {
        Menu {
            ForEach($columns) { $col in
                Toggle(isOn: $col.isVisible) {
                    Text(displayName(for: col.id))
                }
                .onChange(of: col.isVisible) { _, _ in onChange() }
            }
        } label: {
            Image(systemName: "tablecells")
        }
        .menuStyle(.borderlessButton)
        .help("Columns")
    }
    
    private func displayName(for id: String) -> String {
        switch id {
        case "name": return "Name"
        case "size": return "Size"
        case "dateModified": return "Date Modified"
        case "kind": return "Kind"
        case "dateCreated": return "Created"
        default: return id
        }
    }
}
