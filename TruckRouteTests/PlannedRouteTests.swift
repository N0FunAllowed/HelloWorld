import CoreLocation
import XCTest
@testable import TruckRoute

final class PlannedRouteTests: XCTestCase {
    /// A day that runs 10 empty miles to a pickup, 100 loaded to the drop-off,
    /// then 50 empty back to the yard.
    private func sampleRoute(rate: Double? = nil) -> PlannedRoute {
        var pickup = stop(.pickup, rate: rate)
        pickup.distance = 10 * metersPerMile

        var dropoff = stop(.dropoff, rate: rate)
        dropoff.distance = 100 * metersPerMile
        dropoff.allMiles = 110 * metersPerMile

        var home = stop(.end)
        home.distance = 50 * metersPerMile

        return PlannedRoute(stops: [stop(.start), pickup, dropoff, home])
    }

    private func stop(_ kind: StopKind, rate: Double? = nil) -> RouteStop {
        RouteStop(
            kind: kind,
            placeName: "Somewhere",
            address: "1 Main St",
            coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            loadReference: nil,
            day: nil,
            loadRate: rate
        )
    }

    func testLoadedMilesCountOnlyLegsIntoADropOff() {
        XCTAssertEqual(sampleRoute().loadedDistance / metersPerMile, 100, accuracy: 0.001)
    }

    func testEmptyMilesIncludeTheRunToPickupAndTheRunHome() {
        XCTAssertEqual(sampleRoute().emptyDistance / metersPerMile, 60, accuracy: 0.001)
    }

    func testDeadheadShareIsEmptyMilesOverEveryMile() {
        XCTAssertEqual(try XCTUnwrap(sampleRoute().deadheadShare), 60.0 / 160.0, accuracy: 0.001)
    }

    func testRatePerMileIsMeasuredOverEmptyMilesToo() throws {
        // $1,000 over 160 miles driven, not the 100 loaded ones.
        let route = sampleRoute(rate: 1000)
        XCTAssertEqual(try XCTUnwrap(route.ratePerMile), 6.25, accuracy: 0.001)
    }

    func testLoadRatePerMileIncludesItsOwnDeadhead() throws {
        let dropoff = try XCTUnwrap(sampleRoute(rate: 1000).stops.first { $0.kind == .dropoff })
        XCTAssertEqual(try XCTUnwrap(dropoff.ratePerMile), 1000.0 / 110.0, accuracy: 0.001)
    }

    func testTotalRateCountsEachLoadOnceRatherThanPerStop() throws {
        // The rate rides on both the pickup and the drop-off stop.
        XCTAssertEqual(try XCTUnwrap(sampleRoute(rate: 1000).totalRate), 1000, accuracy: 0.001)
    }

    func testRateIsNilWhenNoLoadHasOne() {
        XCTAssertNil(sampleRoute().totalRate)
        XCTAssertNil(sampleRoute().ratePerMile)
    }

    func testWorkingStopCountExcludesTheYardAtBothEnds() {
        XCTAssertEqual(sampleRoute().workingStopCount, 2)
    }

    func testUnmeasuredLegsAreCountedSoTotalsCanBeFlaggedAsLow() {
        var route = sampleRoute()
        route.stops[2].distance = nil
        XCTAssertEqual(route.unmeasuredLegs, 1)
    }

    func testEmptyRouteReportsNothingRatherThanDividingByZero() {
        let empty = PlannedRoute()
        XCTAssertEqual(empty.totalDistance, 0)
        XCTAssertNil(empty.deadheadShare)
        XCTAssertNil(empty.ratePerMile)
        XCTAssertEqual(empty.workingStopCount, 0)
    }
}
