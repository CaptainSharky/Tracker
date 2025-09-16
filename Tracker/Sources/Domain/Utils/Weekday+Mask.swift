extension Weekday {
    var bitIndex: Int16 {
        switch self {
        case .monday:
            return 0
        case .tuesday:
            return 1
        case .wednesday:
            return 2
        case .thursday:
            return 3
        case .friday:
            return 4
        case .saturday:
            return 5
        case .sunday:
            return 6
        }
    }

    var bitMask: Int16 { 1 << bitIndex }

    static func mask(for set: Set<Weekday>) -> Int16 {
        set.reduce(Int16(0)) { $0 | $1.bitMask }
    }

    static func set(from mask: Int16) -> Set<Weekday> {
        var result = Set<Weekday>()
        for day in Weekday.allCases {
            if (mask & day.bitMask) != 0 { result.insert(day) }
        }
        return result
    }
}
