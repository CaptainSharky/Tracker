import CoreData

struct Statistics {
    let bestStreak: Int
    let perfectDays: Int
    let totalCompletions: Int
    let averagePerDay: Int

    static let zero = Statistics(bestStreak: 0, perfectDays: 0, totalCompletions: 0, averagePerDay: 0)

    var isEmpty: Bool {
        bestStreak == 0 && perfectDays == 0 && totalCompletions == 0 && averagePerDay == 0
    }
}

final class StatisticsProvider {
    private let context: NSManagedObjectContext
    private var scheduledCountCache: [Weekday: Int] = [:]

    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext) {
        self.context = context
    }

    func compute() throws -> Statistics {
        let total = try totalCompletions()
        let uniqueDays = try uniqueCompletionDaysCount()
        let average = uniqueDays > 0 ? Int((Double(total) / Double(uniqueDays)).rounded()) : 0
        let perfect = try perfectDaysCount()
        let best = try bestStreakAcrossTrackers()

        return Statistics(
            bestStreak: best,
            perfectDays: perfect,
            totalCompletions: total,
            averagePerDay: average
        )
    }

    private func totalCompletions() throws -> Int {
        let req = NSFetchRequest<NSManagedObject>(entityName: "TrackerRecordEntity")
        return try context.count(for: req)
    }

    private func uniqueCompletionDaysCount() throws -> Int {
        let req = NSFetchRequest<NSDictionary>(entityName: "TrackerRecordEntity")
        req.resultType = .dictionaryResultType
        req.propertiesToFetch = ["date"]
        req.returnsDistinctResults = true
        let rows = try context.fetch(req)
        return rows.count
    }

    private func perfectDaysCount() throws -> Int {
        let countDesc = NSExpressionDescription()
        countDesc.name = "cnt"
        countDesc.expression = NSExpression(forFunction: "count:", arguments: [NSExpression(forKeyPath: "date")])
        countDesc.expressionResultType = .integer32AttributeType

        let req = NSFetchRequest<NSDictionary>(entityName: "TrackerRecordEntity")
        req.resultType = .dictionaryResultType
        req.propertiesToFetch = ["date", countDesc]
        req.propertiesToGroupBy = ["date"]

        let rows = try context.fetch(req)

        var perfect = 0
        let cal = Calendar.current

        for dict in rows {
            guard
                let day = dict["date"] as? Date,
                let recCount = dict["cnt"] as? Int
            else { continue }

            let w = cal.component(.weekday, from: day)
            guard let weekday = Weekday(rawValue: w) else { continue }
            let scheduled = try scheduledCount(for: weekday)

            if scheduled > 0 && recCount == scheduled {
                perfect += 1
            }
        }
        return perfect
    }

    private func scheduledCount(for weekday: Weekday) throws -> Int {
        if let cached = scheduledCountCache[weekday] { return cached }
        let request = NSFetchRequest<NSManagedObject>(entityName: "TrackerEntity")
        request.predicate = NSPredicate(format: "(schedule & %d) != 0", weekday.bitMask)
        let count = try context.count(for: request)
        scheduledCountCache[weekday] = count
        return count
    }

    private func bestStreakAcrossTrackers() throws -> Int {
        let trackersRequest = NSFetchRequest<NSManagedObject>(entityName: "TrackerEntity")
        let trackers = try context.fetch(trackersRequest)

        var best = 0
        for tracker in trackers {
            guard
                let id = tracker.value(forKey: "id") as? UUID,
                let mask = tracker.value(forKey: "schedule") as? Int16
            else { continue }

            let schedule = Weekday.set(from: mask)
            let streak = try bestStreak(for: id, schedule: schedule)
            if streak > best { best = streak }
        }
        return best
    }

    private func bestStreak(for trackerID: UUID, schedule: Set<Weekday>) throws -> Int {
        let request = NSFetchRequest<NSManagedObject>(entityName: "TrackerRecordEntity")
        request.predicate = NSPredicate(format: "tracker.id == %@", trackerID as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        let rows = try context.fetch(request)

        let dates: [Date] = rows.compactMap { $0.value(forKey: "date") as? Date }
        guard !dates.isEmpty else { return 0 }

        let calendar = Calendar.current
        var longest = 1
        var current = 1

        for i in 1..<dates.count {
            let prev = dates[i - 1]
            let curr = dates[i]
            let expected = nextScheduledDate(after: prev, schedule: schedule, calendar: calendar)

            if calendar.isDate(expected, inSameDayAs: curr) {
                current += 1
            } else {
                current = 1
            }
            if current > longest { longest = current }
        }
        return longest
    }

    private func nextScheduledDate(after date: Date, schedule: Set<Weekday>, calendar: Calendar) -> Date {
        if schedule.isEmpty {
            return calendar.startOfDay(
                for: calendar.date(
                    byAdding: .day,
                    value: 1,
                    to: date
                ) ?? date
            )
        }
        var d = date
        while true {
            d = calendar.date(byAdding: .day, value: 1, to: d) ?? d
            let w = calendar.component(.weekday, from: d)
            if let wd = Weekday(rawValue: w), schedule.contains(wd) {
                return calendar.startOfDay(for: d)
            }
        }
    }
}
