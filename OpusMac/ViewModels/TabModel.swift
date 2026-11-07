import Foundation
import SwiftUI
import Combine

@MainActor
final class TabModel: ObservableObject, Identifiable {
    let id = UUID()
    @Published var title: String
    @Published var pane: PaneModel
    
    private var cancellables = Set<AnyCancellable>()
    
    init(url: URL = FileManager.default.homeDirectoryForCurrentUser) {
        self.pane = PaneModel(url: url)
        self.title = url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent
        
        self.pane.$currentURL
            .receive(on: RunLoop.main)
            .sink { [weak self] newURL in
                self?.title = newURL.lastPathComponent.isEmpty ? newURL.path : newURL.lastPathComponent
            }
            .store(in: &cancellables)
    }
}

@MainActor
final class PaneTabManager: ObservableObject {
    @Published var tabs: [TabModel] = []
    @Published var selectedTabID: TabModel.ID?
    
    var selectedTab: TabModel? {
        tabs.first { $0.id == selectedTabID }
    }
    
    var selectedPane: PaneModel? {
        selectedTab?.pane
    }
    
    init(initialURL: URL = FileManager.default.homeDirectoryForCurrentUser) {
        let first = TabModel(url: initialURL)
        tabs = [first]
        selectedTabID = first.id
    }
    
    func addTab(url: URL? = nil) {
        let newTab = TabModel(url: url ?? selectedPane?.currentURL ?? FileManager.default.homeDirectoryForCurrentUser)
        tabs.append(newTab)
        selectedTabID = newTab.id
    }
    
    func closeTab(_ id: TabModel.ID) {
        guard tabs.count > 1 else { return }
        if let idx = tabs.firstIndex(where: { $0.id == id }) {
            tabs.remove(at: idx)
            if selectedTabID == id {
                selectedTabID = tabs[min(idx, tabs.count - 1)].id
            }
        }
    }
    
    func selectTab(_ id: TabModel.ID) {
        selectedTabID = id
    }
}
