import Foundation
import CoreLocation
import MapKit

enum StopKind {
    case start
    case pickup
    case dropoff
    case end

    var label: String {
        switch self {
        case .start: "Start"
        case .pickup: "Pick up"
        case .dropoff: "Drop off"
        case .end: "Back to yard"
        }
    }
}

struct RouteStop: Identifiable {
    let id = UUID()
    let kind: StopKind
    let placeName: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let loadReference: String?
    let day: Date?
    /// What the load this stop belongs to pays. Nil on the start.
    let loadRate: Double?
    /// Estimated operating cost for the load. Nil on the start and end.
    let loadCost: Double?

    /// Drive from the previous stop to this one. Nil for the start, or if
    /// MapKit couldn't find a road route.
    var travelTime: TimeInterval?
    var distance: CLLocationDistance?
    var polyline: MKPolyline?

    /// Every leg driven to earn this load: the empty run to its pickup plus
    /// the loaded run to its drop-off. Set on drop-off stops once legs are
    /// measured.
    var allMiles: CLLocationDistance?

    /// The leg arriving here is empty — running to a pickup with nothing on,
    /// or heading home after the last drop. Empty miles earn nothing, so
    /// they're what separates a good rate from a bad one.
    var isDeadheadLeg: Bool { kind == .pickup || kind == .end }

    /// Rate per mile measured against all miles, loaded and empty, which is how
    /// owner-operators judge a load.
    var ratePerMile: Double? {
        guard let loadRate, let allMiles, allMiles > 0 else { return nil }
        return loadRate / (allMiles / 1609.344)
    }
}

/// A load left out of the route, because it has no pickup or drop-off set or
/// because an address wouldn't geocode.
struct SkippedLoad: Identifiable {
    let id = UUID()
    let reference: String
    let reason: String
}

struct PlannedRoute {
    var stops: [RouteStop] = []
    var skipped: [SkippedLoad] = []

    /// Pickups and drop-offs, not the yard at either end.
    var workingStopCount: Int {
        stops.filter { $0.kind == .pickup || $0.kind == .dropoff }.count
    }

    var totalDistance: CLLocationDistance {
        stops.compactMap(\.distance).reduce(0, +)
    }

    var totalTravelTime: TimeInterval {
        stops.compactMap(\.travelTime).reduce(0, +)
    }

    var loadedDistance: CLLocationDistance {
        stops.filter { !$0.isDeadheadLeg }.compactMap(\.distance).reduce(0, +)
    }

    var emptyDistance: CLLocationDistance {
        stops.filter(\.isDeadheadLeg).compactMap(\.distance).reduce(0, +)
    }

    var deadheadShare: Double? {
        guard totalDistance > 0 else { return nil }
        return emptyDistance / totalDistance
    }

    /// Nil when no load on the route has a rate entered.
    var totalRate: Double? {
        let rates = stops.filter { $0.kind == .dropoff }.compactMap(\.loadRate)
        return rates.isEmpty ? nil : rates.reduce(0, +)
    }

    var totalCost: Double? {
        let costs = stops.filter { $0.kind == .dropoff }.compactMap(\.loadCost)
        return costs.isEmpty ? nil : costs.reduce(0, +)
    }

    var totalProfit: Double? {
        guard let totalRate, let totalCost else { return nil }
        return totalRate - totalCost
    }

    var profitMargin: Double? {
        guard let totalRate, totalRate > 0, let totalProfit else { return nil }
        return totalProfit / totalRate
    }

    /// Revenue over every mile of the route, empty ones included.
    var ratePerMile: Double? {
        guard let totalRate, totalDistance > 0 else { return nil }
        return totalRate / (totalDistance / 1609.344)
    }
}
