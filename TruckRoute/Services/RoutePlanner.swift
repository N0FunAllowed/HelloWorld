import Foundation
import CoreLocation
import MapKit
import Observation

@MainActor
@Observable
final class RoutePlanner {
    private(set) var route: PlannedRoute?
    private(set) var isPlanning = false
    private(set) var progressNote: String?
    private(set) var errorMessage: String?

    /// Orders the week's loads and measures each leg.
    ///
    /// Loads are grouped by pickup day so the truck never runs a Friday load on
    /// Monday, then ordered within each day by nearest-neighbor: from where the
    /// truck currently sits, take the closest remaining pickup, run it to its
    /// drop-off, repeat. Distance for ordering is straight-line — good enough to
    /// pick the next stop, and it avoids a directions request per candidate.
    func plan(loads: [Load], from homeBase: Place) async {
        guard !isPlanning else { return }
        isPlanning = true
        errorMessage = nil
        defer {
            isPlanning = false
            progressNote = nil
        }

        guard !loads.isEmpty else {
            route = PlannedRoute()
            return
        }

        progressNote = "Looking up addresses…"
        let start: CLLocationCoordinate2D
        do {
            start = try await resolveCoordinate(for: homeBase)
        } catch {
            errorMessage = "Couldn't find the address for \(homeBase.displayName), your home base."
            return
        }

        var routable: [(load: Load, pickup: CLLocationCoordinate2D, dropoff: CLLocationCoordinate2D)] = []
        var skipped: [SkippedLoad] = []

        for load in loads {
            guard let pickup = load.pickup, let dropoff = load.dropoff else {
                skipped.append(SkippedLoad(
                    reference: load.displayName,
                    reason: "No pickup or drop-off set."
                ))
                continue
            }
            do {
                routable.append((
                    load,
                    try await resolveCoordinate(for: pickup),
                    try await resolveCoordinate(for: dropoff)
                ))
            } catch {
                skipped.append(SkippedLoad(
                    reference: load.displayName,
                    reason: error.localizedDescription
                ))
            }
        }

        var stops = [RouteStop(
            kind: .start,
            placeName: homeBase.displayName,
            address: homeBase.address,
            coordinate: start,
            loadReference: nil,
            day: nil,
            loadRate: nil,
            loadCost: nil
        )]

        let calendar = Calendar.current
        let byDay = Dictionary(grouping: routable) {
            calendar.startOfDay(for: $0.load.pickupDate)
        }

        var current = start
        for day in byDay.keys.sorted() {
            var remaining = byDay[day] ?? []
            while !remaining.isEmpty {
                let index = remaining.indices.min { a, b in
                    distance(from: current, to: remaining[a].pickup)
                        < distance(from: current, to: remaining[b].pickup)
                }!
                let entry = remaining.remove(at: index)
                stops.append(RouteStop(
                    kind: .pickup,
                    placeName: entry.load.pickup?.displayName ?? "",
                    address: entry.load.pickup?.address ?? "",
                    coordinate: entry.pickup,
                    loadReference: entry.load.displayName,
                    day: day,
                    loadRate: entry.load.rate,
                    loadCost: entry.load.totalCost
                ))
                stops.append(RouteStop(
                    kind: .dropoff,
                    placeName: entry.load.dropoff?.displayName ?? "",
                    address: entry.load.dropoff?.address ?? "",
                    coordinate: entry.dropoff,
                    loadReference: entry.load.displayName,
                    day: day,
                    loadRate: entry.load.rate,
                    loadCost: entry.load.totalCost
                ))
                current = entry.dropoff
            }
        }

        // The empty run home is real deadhead, so the day isn't costed
        // honestly without it.
        if stops.count > 1 {
            stops.append(RouteStop(
                kind: .end,
                placeName: homeBase.displayName,
                address: homeBase.address,
                coordinate: start,
                loadReference: nil,
                day: nil,
                loadRate: nil,
                loadCost: nil
            ))
        }

        route = PlannedRoute(stops: stops, skipped: skipped)
        await measureLegs()
    }

    func clear() {
        route = nil
        errorMessage = nil
    }

    /// Geocodes a place once and caches the result on it, so replanning and
    /// other loads using the same place cost nothing.
    private func resolveCoordinate(for place: Place) async throws -> CLLocationCoordinate2D {
        if let cached = place.coordinate { return cached }
        let coordinate = try await GeocodingService.shared.coordinate(for: place.address)
        place.coordinate = coordinate
        return coordinate
    }

    /// Fills in drive time, distance and the drawable polyline for each leg.
    /// A leg that MapKit can't route (islands, bad address, throttling) stays
    /// nil rather than falling back to a straight line that would understate
    /// the real drive.
    private func measureLegs() async {
        guard var working = route else { return }

        for index in working.stops.indices.dropFirst() {
            progressNote = "Measuring leg \(index) of \(working.stops.count - 1)…"

            let request = MKDirections.Request()
            request.source = MKMapItem(
                placemark: MKPlacemark(coordinate: working.stops[index - 1].coordinate)
            )
            request.destination = MKMapItem(
                placemark: MKPlacemark(coordinate: working.stops[index].coordinate)
            )
            request.transportType = .automobile

            if let leg = try? await MKDirections(request: request).calculate().routes.first {
                working.stops[index].travelTime = leg.expectedTravelTime
                working.stops[index].distance = leg.distance
                working.stops[index].polyline = leg.polyline
            }
            route = working
        }

        // A load's miles are the empty run to its pickup plus the loaded run to
        // its drop-off. Stops are built pickup-then-drop-off, so the leg before
        // a drop-off is always that load's deadhead.
        for index in working.stops.indices where working.stops[index].kind == .dropoff {
            let loaded = working.stops[index].distance ?? 0
            let empty = index > 0 ? (working.stops[index - 1].distance ?? 0) : 0
            working.stops[index].allMiles = loaded + empty
        }
        route = working
    }

    private func distance(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D
    ) -> CLLocationDistance {
        CLLocation(latitude: from.latitude, longitude: from.longitude)
            .distance(from: CLLocation(latitude: to.latitude, longitude: to.longitude))
    }
}
