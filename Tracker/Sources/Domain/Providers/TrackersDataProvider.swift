import CoreData
import UIKit

enum CompletionFilter {
    case completed(Date)
    case notCompleted(Date)
}

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
        if let completion = filter.completion {
            let (start, end) = Self.dayBounds(for: {
                switch completion {
                case .completed(let d), .notCompleted(let d): return d
                }
            }())

            switch completion {
            case .completed:
                let p = NSPredicate(
                    format: "SUBQUERY(records, $r, $r.date >= %@ AND $r.date < %@).@count > 0",
                    start as NSDate, end as NSDate
                )
                predicates.append(p)
            case .notCompleted:
                let p = NSPredicate(
                    format: "SUBQUERY(records, $r, $r.date >= %@ AND $r.date < %@).@count == 0",
                    start as NSDate, end as NSDate
                )
                predicates.append(p)
            }
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

    private static func dayBounds(for date: Date) -> (Date, Date) {
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start
        return (start, end)
    }
}

extension TrackersDataProvider: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
        onChange?()
    }
}
