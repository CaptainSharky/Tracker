final class CategoryModel {
    private let store: TrackerCategoryStore

    init(store: TrackerCategoryStore = TrackerCategoryStore()) {
        self.store = store
    }

    func fetchCategories() -> [Category] {
        let titles = (try? store.allTitles()) ?? []
        return titles.map { Category(title: $0, isSelected: false) }
    }

    func createCategory(title: String) throws {
        try store.getOrCreate(title: title)
    }

    func renameCategory(oldTitle: String, newTitle: String) throws {
        try store.rename(from: oldTitle, to: newTitle)
    }

    func deleteCategory(title: String, reassignTo fallbackTitle: String) throws {
        try store.delete(title: title, reassigningTrackersTo: fallbackTitle)
    }
}
