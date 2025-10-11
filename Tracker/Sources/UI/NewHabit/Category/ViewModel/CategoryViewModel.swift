typealias Binding<T> = (T) -> Void

final class CategoryViewModel {
    var onCategoriesChanged: Binding<Void>?
    var onEmptyStateChanged: Binding<Bool>?
    var onSelectedChanged: Binding<String?>?

    private(set) var items: [Category] = [] {
        didSet {
            onCategoriesChanged?(())
            onEmptyStateChanged?(items.isEmpty)
        }
    }

    private(set) var selectedTitle: String? {
        didSet { onSelectedChanged?(selectedTitle) }
    }

    private let model: CategoryModel
    private let fallBackCategoryTitle = "Без категории"

    init(model: CategoryModel = CategoryModel(), preselectedTitle: String? = nil) {
        self.model = model
        self.selectedTitle = preselectedTitle
    }

    func load() {
        items = model.fetchCategories().map {
            Category(title: $0.title, isSelected: $0.title == selectedTitle)
        }
    }

    func numberOfRows() -> Int { items.count }

    func title(at index: Int) -> String { items[index].title }

    func isSelected(at index: Int) -> Bool { items[index].isSelected }

    func select(at index: Int) {
        for i in items.indices { items[i].isSelected = (i == index) }
        selectedTitle = items[index].title
    }

    func addCategory(title: String) {
        try? model.createCategory(title: title)
        selectedTitle = title
        load()
    }

    func renameCategory(oldTitle: String, newTitle: String) {
        try? model.renameCategory(oldTitle: oldTitle, newTitle: newTitle)
        if selectedTitle == oldTitle { selectedTitle = newTitle }
        load()
    }

    func deleteCategory(title: String) {
        try? model.deleteCategory(title: title, reassignTo: fallBackCategoryTitle)
        if selectedTitle == title { selectedTitle = nil }
        load()
    }
}
