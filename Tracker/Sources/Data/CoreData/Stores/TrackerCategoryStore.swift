import CoreData

final class TrackerCategoryStore: TrackerCategoryStoreProtocol {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext) {
        self.context = context
    }

    func getOrCreate(title: String) throws {
        _ = try fetchOrInsert(title: title)
        try CoreDataStack.shared.saveContext(context)
    }
    
    func allTitles() throws -> [String] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "TrackerCategoryEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        let list = try context.fetch(request)
        return list.compactMap { $0.value(forKey: "title") as? String }
    }
    
    func fetchOrInsert(title: String) throws -> NSManagedObject {
        if let found = try fetch(title: title) { return found }
        let entity = NSEntityDescription.insertNewObject(
            forEntityName: "TrackerCategoryEntity",
            into: context
        )
        entity.setValue(title, forKey: "title")
        return entity
    }

    func fetch(title: String) throws -> NSManagedObject? {
        let request = NSFetchRequest<NSManagedObject>(entityName: "TrackerCategoryEntity")
        request.predicate = NSPredicate(format: "title == %@", title)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}
