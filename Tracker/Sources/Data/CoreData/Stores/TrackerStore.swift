import CoreData

final class TrackerStore: TrackerStoreProtocol {
    private let context: NSManagedObjectContext
    private let categoryStore: TrackerCategoryStore

    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext,
         categoryStore: TrackerCategoryStore = TrackerCategoryStore()) {
        self.context = context
        self.categoryStore = categoryStore
    }

    func create(_ tracker: Tracker, inCategory title: String) throws {
        let trackerEntity = NSEntityDescription.insertNewObject(forEntityName: "TrackerEntity", into: context)
        let category = try categoryStore.fetchOrInsert(title: title)

        trackerEntity.setValue(tracker.id, forKey: "id")
        trackerEntity.setValue(tracker.title, forKey: "title")
        trackerEntity.setValue(tracker.color.hexRGB, forKey: "colorHex")
        trackerEntity.setValue(tracker.emoji, forKey: "emoji")
        trackerEntity.setValue(Weekday.mask(for: tracker.schedule), forKey: "schedule")
        trackerEntity.setValue(category, forKey: "category")

        try CoreDataStack.shared.saveContext(context)
    }

    func update(_ tracker: Tracker, inCategory title: String?) throws {
        guard let entity = try fetchEntity(id: tracker.id) else { throw StoreError.notFound }
        entity.setValue(tracker.title, forKey: "title")
        entity.setValue(tracker.color.hexRGB, forKey: "colorHex")
        entity.setValue(tracker.emoji, forKey: "emoji")
        entity.setValue(Weekday.mask(for: tracker.schedule), forKey: "schedule")
        if let title {
            let category = try categoryStore.fetchOrInsert(title: title)
            entity.setValue(category, forKey: "category")
        }
        try CoreDataStack.shared.saveContext(context)
    }

    func delete(id: UUID) throws {
        guard let entity = try fetchEntity(id: id) else { return }
        context.delete(entity)
        try CoreDataStack.shared.saveContext(context)
    }

    func fetchEntity(id: UUID) throws -> NSManagedObject? {
        let request = NSFetchRequest<NSManagedObject>(entityName: "TrackerEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}
