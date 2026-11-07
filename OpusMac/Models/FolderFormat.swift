import Foundation

enum ViewMode: String, Codable, CaseIterable, Identifiable {
    case details
    case icons
    case list
    case thumbnails
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .details:     return "Details"
        case .icons:       return "Icons"
        case .list:        return "List"
        case .thumbnails:  return "Thumbnails"
        }
    }
    
    var iconName: String {
        switch self {
        case .details:     return "list.bullet.rectangle"
        case .icons:       return "square.grid.2x2"
        case .list:        return "list.bullet"
        case .thumbnails:  return "photo.on.rectangle"
        }
    }
}

struct ColumnConfig: Codable, Identifiable, Hashable {
    var id: String
    var isVisible: Bool
    var width: Double
    
    static let defaults: [ColumnConfig] = [
        ColumnConfig(id: "name",         isVisible: true, width: 280),
        ColumnConfig(id: "size",         isVisible: true, width: 100),
        ColumnConfig(id: "dateModified", isVisible: true, width: 160),
        ColumnConfig(id: "kind",         isVisible: true, width: 140),
        ColumnConfig(id: "dateCreated",  isVisible: true, width: 140)
    ]
}

struct FolderFormat: Codable, Equatable {
    var viewMode: ViewMode = .details
    var columns: [ColumnConfig] = ColumnConfig.defaults
    var sortColumn: String = "name"
    var sortAscending: Bool = true
    var thumbnailSize: Double = 80
    var showHiddenFiles: Bool = false
    var flatView: Bool = false
    var showInvisibles: Bool = false
    
    static let `default` = FolderFormat()
    
    func width(for columnId: String) -> Double {
        columns.first { $0.id == columnId }?.width ?? 100
    }
    
    mutating func setWidth(_ width: Double, for columnId: String) {
        if let idx = columns.firstIndex(where: { $0.id == columnId }) {
            columns[idx].width = width
        }
    }
}
