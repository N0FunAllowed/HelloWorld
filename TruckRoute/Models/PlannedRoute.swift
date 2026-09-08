import Foundation
import CoreLocation
import MapKit

enum StopKind {
    case start
    case pickup
    case dropoff

    var label: String {
        switch self {
        case .start: "Start"
        case .pickup: "Pick up"
        case .dropoff: "Drop off"
        }
    }
}

struct RouteStop: Identifiable {
    let id = UUID()
    let kind: StopKind
    let address: String
    let coordinate: CLLocationCoordinate2D
    let loadReference: String?
    let day: Date?

    /// Drive from the previous stop to this one. Nil for the start, or if
    /// MapKit couldn't find a road route.
    var travelTime: TimeInterval?
    var distance: CLLocationDistance?
    var polyline: MKPolyline?
}

/// A load left out of the route because an address wouldn't geocode.
struct SkippedLoad: Identifiable {
    let id = UUID()
    let reference: String
    let reason: String
}

struct PlannedRoute {
    var stops: [RouteStop] = []
    var skipped: [SkippedLoad] = []

    var totalDistance: CLLocationDistance {
        stops.compactMap(\.distance).reduce(0, +)
    }

    var totalTravelTime: TimeInterval {
        stops.compactMap(\.travelTime).reduce(0, +)
    }
}
