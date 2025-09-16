import CoreData

final class CoreDataStack {
    static let shared = CoreDataStack()

    let container: NSPersistentContainer
    var viewContext: NSManagedObjectContext { container.viewContext }

    private init() {
        container = NSPersistentContainer(name: "Trackers")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                fatalError("CoreData load error: \(error)")
            }
        })
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    func saveContext(_ context: NSManagedObjectContext? = nil) throws {
        let cont = context ?? viewContext
        if cont.hasChanges {
            do {
                try cont.save()
            } catch { throw StoreError.persistence(error) }
        }
    }
}
