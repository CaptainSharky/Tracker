import Foundation

protocol TrackerStoreProtocol {
    func create(_ tracker: Tracker, inCategory title: String) throws
    func update(_ tracker: Tracker, inCategory title: String?) throws
    func delete(id: UUID) throws
}

struct TrackerFilter {
    var weekday: Weekday?
    var search: String?

    init(weekday: Weekday? = nil, search: String? = nil) {
        self.weekday = weekday
        self.search = search
    }
}
