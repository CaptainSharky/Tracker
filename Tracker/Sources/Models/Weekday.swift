import Foundation

enum Weekday: Int, CaseIterable, Codable {
    case monday = 2, tuesday = 3, wednesday = 4, thursday = 5, friday = 6, saturday = 7, sunday = 1

    var shortTitle: String {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "ru_RU")
        let symbols = calendar.shortWeekdaySymbols[rawValue - 1]
        return symbols
    }

    var title: String {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "ru_RU")
        let symbols = calendar.weekdaySymbols[rawValue - 1]
        return symbols.capitalized(with: calendar.locale)
    }
}
