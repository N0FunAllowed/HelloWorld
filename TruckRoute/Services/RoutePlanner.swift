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
    func plan(loads: [Load], startingFrom homeBase: String) async {
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
        var start: CLLocationCoordinate2D
        do {
            start = try await GeocodingService.shared.coordinate(for: homeBase)
        } catch {
            errorMessage = "Couldn't find your home base address. Check it in Settings."
            return
        }

        var routable: [Load] = []
        var skipped: [SkippedLoad] = []
        for load in loads {
            do {
                try await resolveCoordinates(for: load)
                routable.append(load)
            } catch {
                skipped.append(SkippedLoad(
                    reference: load.displayName,
                    reason: error.localizedDescription
                ))
            }
        }

        var stops = [RouteStop(
            kind: .start,
            address: homeBase,
            coordinate: start,
            loadReference: nil,
            day: nil
        )]

        let calendar = Calendar.current
        let byDay = Dictionary(grouping: routable) { calendar.startOfDay(for: $0.pickupDate) }

        var current = start
        for day in byDay.keys.sorted() {
            var remaining = byDay[day] ?? []
            while !remaining.isEmpty {
                let index = remaining.indices.min { a, b in
                    distance(from: current, to: remaining[a].pickupCoordinate!)
                        < distance(from: current, to: remaining[b].pickupCoordinate!)
                }!
                let load = remaining.remove(at: index)
                stops.append(RouteStop(
                    kind: .pickup,
                    address: load.pickupAddress,
                    coordinate: load.pickupCoordinate!,
                    loadReference: load.displayName,
                    day: day
                ))
                stops.append(RouteStop(
                    kind: .dropoff,
                    address: load.dropoffAddress,
                    coordinate: load.dropoffCoordinate!,
                    loadReference: load.displayName,
                    day: day
                ))
                current = load.dropoffCoordinate!
            }
        }

        route = PlannedRoute(stops: stops, skipped: skipped)
        await measureLegs()
    }

    func clear() {
        route = nil
        errorMessage = nil
    }

    private func resolveCoordinates(for load: Load) async throws {
        if load.pickupCoordinate == nil {
            load.pickupCoordinate = try await GeocodingService.shared
                .coordinate(for: load.pickupAddress)
        }
        if load.dropoffCoordinate == nil {
            load.dropoffCoordinate = try await GeocodingService.shared
                .coordinate(for: load.dropoffAddress)
        }
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
    }

    private func distance(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D
    ) -> CLLocationDistance {
        CLLocation(latitude: from.latitude, longitude: from.longitude)
            .distance(from: CLLocation(latitude: to.latitude, longitude: to.longitude))
    }
}
