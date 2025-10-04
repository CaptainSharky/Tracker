final class CategoryModel {
    private let store: TrackerCategoryStore

    init(store: TrackerCategoryStore = TrackerCategoryStore()) {
        self.store = store
    }

    func fetchCategories() -> [Category] {
        let titles = (try? store.allTitles()) ?? []
        return titles.map { Category(title: $0, isSelected: false) }
    }
}
