enum AnalyticsEvent {
    case open(screen: Screen)
    case close(screen: Screen)
    case click(screen: Screen, item: Item)

    var name: String {
        switch self {
        case .open:
            return "open"
        case .close:
            return "close"
        case .click:
            return "click"
        }
    }

    var parameters: [String: String] {
        switch self {
        case .open(let screen), .close(let screen):
            return ["screen": screen.rawValue]
        case .click(let screen, let item):
            return ["screen": screen.rawValue, "item": item.rawValue]
        }
    }

    enum Screen: String {
        case main = "Main"
        case statistics = "Statistics"
        case onboarding = "Onboarding"
    }

    enum Item: String {
        case addTrack = "add_track"
        case track = "track"
        case filter = "filter"
        case edit = "edit"
        case delete = "delete"
    }
}
