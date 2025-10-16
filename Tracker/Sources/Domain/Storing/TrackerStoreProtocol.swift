import Foundation

protocol TrackerStoreProtocol {
    func create(_ tracker: Tracker, inCategory title: String) throws
    func update(_ tracker: Tracker, inCategory title: String?) throws
    func delete(id: UUID) throws
}

struct TrackerFilter {
    var weekday: Weekday?
    var search: String?
    var completion: CompletionFilter?

    init(weekday: Weekday? = nil, search: String? = nil, completion: CompletionFilter? = nil) {
        self.weekday = weekday
        self.search = search
        self.completion = completion
    }
}
