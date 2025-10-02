final class CategoryViewModel {
    var onCategoriesChanged: (() -> Void)?
    var onEmptyStateChanged: ((Bool) -> Void)?
    var onSelectedChanged: ((String?) -> Void)?

    private(set) var items: [CategoryModel] = [] {
        didSet {
            onCategoriesChanged?()
            onEmptyStateChanged?(items.isEmpty)
        }
    }

    private(set) var selectedTitle: String? {
        didSet { onSelectedChanged?(selectedTitle) }
    }

    private let store: TrackerCategoryStore

    init(store: TrackerCategoryStore = TrackerCategoryStore(), preselectedTitle: String? = nil) {
        self.store = store
        self.selectedTitle = preselectedTitle
    }

    func load() {
        let titles = (try? store.allTitles()) ?? []
        items = titles.map { CategoryModel(title: $0, isSelected: $0 == selectedTitle) }
    }

    func numberOfRows() -> Int { items.count }

    func title(at index: Int) -> String { items[index].title }

    func isSelected(at index: Int) -> Bool { items[index].isSelected }

    func select(at index: Int) {
        for i in items.indices { items[i].isSelected = (i == index) }
        selectedTitle = items[index].title
    }
}
