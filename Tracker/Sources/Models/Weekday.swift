import Foundation

enum Weekday: Int, CaseIterable, Codable {
    case monday = 2, tuesday, wednesday, thursday, friday, saturday, sunday

    var shortTitle: String {
        let symbols = Calendar.current.shortWeekdaySymbols
        return symbols[rawValue - 1]
    }
}
