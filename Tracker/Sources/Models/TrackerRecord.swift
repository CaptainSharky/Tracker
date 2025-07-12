import Foundation

struct TrackerRecord: Hashable {
    let trackerID: UUID
    let date: Date

    init(trackerID: UUID, date: Date) {
        self.trackerID = trackerID
        self.date = Calendar.current.startOfDay(for: date)
    }
}
