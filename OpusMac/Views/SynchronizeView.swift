import SwiftUI

struct SynchronizeView: View {
    let leftURL: URL
    let rightURL: URL
    @StateObject private var engine = SynchronizeEngine()
    @State private var selected = Set<SyncItem.ID>()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Left (Source)").font(.caption).foregroundStyle(.secondary)
                    Text(leftURL.path).font(.system(.body, design: .monospaced)).lineLimit(1)
                }
                Spacer()
                Image(systemName: "arrow.left.arrow.right").font(.title2).foregroundStyle(.secondary)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Right (Destination)").font(.caption).foregroundStyle(.secondary)
                    Text(rightURL.path).font(.system(.body, design: .monospaced)).lineLimit(1)
                }
            }.padding()
            Divider()
            HStack {
                Button("Compare") { Task { await engine.compare(left: leftURL, right: rightURL) } }
                    .disabled(engine.isScanning || engine.isSyncing)
                Button("Select All") { selected = Set(engine.items.map(\.id)) }.disabled(engine.items.isEmpty)
                Button("Select None") { selected = [] }.disabled(selected.isEmpty)
                Spacer()
                if engine.isScanning || engine.isSyncing {
                    ProgressView(value: engine.progress).frame(width: 120)
                    Text(engine.statusMessage).font(.caption).foregroundStyle(.secondary)
                } else {
                    Text(engine.statusMessage).font(.caption).foregroundStyle(.secondary)
                }
                Button("Sync Selected") {
                    Task { await engine.sync(selected: selected); selected = [] }
                }
                .disabled(selected.isEmpty || engine.isSyncing)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal).padding(.vertical, 8)
            Divider()
            Table(engine.items, selection: $selected) {
                TableColumn("Dir") { item in
                    Text(item.direction.rawValue).font(.headline)
                        .foregroundStyle(item.direction == .leftToRight ? .blue : .orange)
                }.width(40)
                TableColumn("Path") { item in Text(item.relativePath).lineLimit(1) }.width(min: 200, ideal: 320)
                TableColumn("Reason") { item in Text(item.reason.rawValue).foregroundStyle(.secondary) }.width(120)
                TableColumn("Size") { item in
                    if let size = item.size {
                        Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                    } else { Text("--") }
                }.width(80)
            }
            Divider()
            HStack {
                Button("Close") { dismiss() }.keyboardShortcut(.cancelAction)
                Spacer()
            }.padding()
        }
        .frame(minWidth: 700, minHeight: 450)
        .navigationTitle("Synchronize")
        .task { await engine.compare(left: leftURL, right: rightURL) }
    }
}
