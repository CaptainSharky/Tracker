import AppMetricaCore

struct AnalyticsService {
    static func activate() {
        guard let configuration = AppMetricaConfiguration(apiKey: "289a851a-2d26-48b6-bff3-88172fd28f12") else { return }

        AppMetrica.activate(with: configuration)
    }

    func report(event: String, params : [AnyHashable : Any]) {
        AppMetrica.reportEvent(name: event, parameters: params, onFailure: { error in
            print("REPORT ERROR: %@", error.localizedDescription)
        })
    }

    func report(_ event: AnalyticsEvent) {
        AppMetrica.reportEvent(
            name: event.name,
            parameters: event.parameters,
            onFailure: { error in
                print("REPORT ERROR: %@", error.localizedDescription)
            }
        )
    }
}
