import CoreData
import UIKit

protocol TrackersDataProviderProtocol {
    var onChange: (() -> Void)? { get set }
    func performFetch(filter: TrackerFilter) throws
    func numberOfSections() -> Int
    func numberOfItems(in section: Int) -> Int
    func tracker(at indexPath: IndexPath) -> Tracker
    func sectionTitle(at section: Int) -> String?
}

final class TrackersDataProvider: NSObject, TrackersDataProviderProtocol {
    private let context: NSManagedObjectContext
    private var fetchResultsController: NSFetchedResultsController<NSManagedObject>?
    var onChange: (() -> Void)?

    init(container: NSPersistentContainer = CoreDataStack.shared.container) {
        context = container.viewContext
        super.init()
    }

    func performFetch(filter: TrackerFilter) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: "TrackerEntity")
        var predicates: [NSPredicate] = []

        if let weekday = filter.weekday {
            let mask = weekday.bitMask
            predicates.append(NSPredicate(format: "(schedule & %d) != 0", mask))
        }
        if let q = filter.search?.trimmingCharacters(in: .whitespacesAndNewlines), !q.isEmpty {
            predicates.append(NSPredicate(format: "title CONTAINS[cd] %@", q))
        }
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        request.sortDescriptors = [
            NSSortDescriptor(key: "category.title", ascending: true),
            NSSortDescriptor(key: "title", ascending: true)
        ]

        let controller = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: "category.title",
            cacheName: nil
        )
        controller.delegate = self
        self.fetchResultsController = controller

        try controller.performFetch()
        onChange?()
    }
    
    func numberOfSections() -> Int {
        fetchResultsController?.sections?.count ?? 0
    }
    
    func numberOfItems(in section: Int) -> Int {
        fetchResultsController?.sections?[section].numberOfObjects ?? 0
    }
    
    func tracker(at indexPath: IndexPath) -> Tracker {
        guard let obj = fetchResultsController?.object(at: indexPath) else {
            fatalError("[TrackersDataProvider]: No object at \(indexPath)")
        }
        guard
            let id = obj.value(forKey: "id") as? UUID,
            let title = obj.value(forKey: "title") as? String,
            let colorHex = obj.value(forKey: "colorHex") as? String,
            let emoji = obj.value(forKey: "emoji") as? String,
            let mask = obj.value(forKey: "schedule") as? Int16
        else {
            fatalError("[TrackersDataProvider]: Wrong properties at \(indexPath)")
        }

        let color = UIColor(hexRGB: colorHex) ?? .black
        let schedule = Weekday.set(from: mask)

        return Tracker(
            id: id,
            title: title,
            color: color,
            emoji: emoji,
            schedule: schedule
        )
    }
    
    func sectionTitle(at section: Int) -> String? {
        fetchResultsController?.sections?[section].name
    }
}

extension TrackersDataProvider: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
        onChange?()
    }
}
