import Foundation

protocol TrackerRecordStoreProtocol {
    func isCompleted(trackerID: UUID, on day: Date) throws -> Bool
    func toggle(trackerID: UUID, on day: Date) throws
    func completionCount(trackerID: UUID) throws -> Int
}
