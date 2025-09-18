import CoreData

final class TrackerRecordStore: TrackerRecordStoreProtocol {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext) {
        self.context = context
    }

    func isCompleted(trackerID: UUID, on day: Date) throws -> Bool {
        let request = recordFetchRequest(trackerID: trackerID, day: day)
        request.fetchLimit = 1
        return try context.count(for: request) > 0
    }
    
    func toggle(trackerID: UUID, on day: Date) throws {
        if try isCompleted(trackerID: trackerID, on: day) {
            try remove(trackerID: trackerID, day: day)
        } else {
            try add(trackerID: trackerID, day: day)
        }
        try CoreDataStack.shared.saveContext(context)
    }

    func completionCount(trackerID: UUID) throws -> Int {
        let request = NSFetchRequest<NSManagedObject>(entityName: "TrackerRecordEntity")
        request.predicate = NSPredicate(format: "tracker.id == %@", trackerID as CVarArg)
        return try context.count(for: request)
    }

    private func add(trackerID: UUID, day: Date) throws {
        let start = Calendar.current.startOfDay(for: day)
        if try isCompleted(trackerID: trackerID, on: start) { return }

        guard let tracker = try fetchTracker(id: trackerID) else { throw StoreError.notFound }
        let record = NSEntityDescription.insertNewObject(forEntityName: "TrackerRecordEntity", into: context)
        record.setValue(start, forKey: "date")
        record.setValue(tracker, forKey: "tracker")
    }

    private func remove(trackerID: UUID, day: Date) throws {
        let request = recordFetchRequest(trackerID: trackerID, day: day)
        let items = try context.fetch(request)
        for item in items { context.delete(item) }
    }

    private func recordFetchRequest(trackerID: UUID, day: Date) -> NSFetchRequest<NSManagedObject> {
        let start = Calendar.current.startOfDay(for: day)
        guard let end = Calendar.current.date(byAdding: .day, value: 1, to: start) else { return NSFetchRequest<NSManagedObject>() }
        let request = NSFetchRequest<NSManagedObject>(entityName: "TrackerRecordEntity")

        request.predicate = NSPredicate(
            format: "tracker.id == %@ AND date >= %@ AND date < %@",
            trackerID as CVarArg, start as NSDate, end as NSDate
        )

        return request
    }

    private func fetchTracker(id: UUID) throws -> NSManagedObject? {
        let request = NSFetchRequest<NSManagedObject>(entityName: "TrackerEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}
