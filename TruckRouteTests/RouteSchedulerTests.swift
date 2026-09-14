import CoreLocation
import XCTest
@testable import TruckRoute

final class RouteSchedulerTests: XCTestCase {
    private let calendar = Calendar.current
    private let coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)

    private func date(_ day: Int, _ hour: Int, _ minute: Int = 0, from base: Date = .now) -> Date {
        let startOfBase = calendar.startOfDay(for: base)
        let targetDay = calendar.date(byAdding: .day, value: day, to: startOfBase)!
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: targetDay)!
    }

    private func stop(
        _ kind: StopKind,
        day: Date? = nil,
        windowStart: Date? = nil,
        deadline: Date? = nil,
        serviceDurationMinutes: Int = 0,
        travelTime: TimeInterval? = nil
    ) -> RouteStop {
        var stop = RouteStop(
            kind: kind,
            placeName: "Somewhere",
            address: "1 Main St",
            coordinate: coordinate,
            loadReference: nil,
            day: day,
            loadRate: nil,
            windowStart: windowStart,
            deadline: deadline,
            serviceDurationMinutes: serviceDurationMinutes
        )
        stop.travelTime = travelTime
        return stop
    }

    // MARK: Future first pickup

    func testAFuturePickupIsScheduledOnItsOwnDayNotToday() throws {
        let pickupDay = date(5, 0)
        let windowStart = date(5, 10)
        let stops = [
            stop(.start),
            stop(.pickup, day: pickupDay, windowStart: windowStart, travelTime: 3600),
        ]

        let scheduled = RouteScheduler.schedule(stops)

        // The yard start never got a day, so it never got a schedule either.
        XCTAssertNil(scheduled[0].scheduledArrival)

        let arrival = try XCTUnwrap(scheduled[1].scheduledArrival)
        XCTAssertEqual(arrival, windowStart)
        XCTAssertTrue(calendar.isDate(arrival, inSameDayAs: pickupDay))
    }

    func testADayWithNoEarlyWindowStartsAtTheDefaultDayStartHour() throws {
        let pickupDay = date(2, 0)
        let stops = [
            stop(.start),
            stop(.pickup, day: pickupDay, travelTime: 1800),
        ]

        let scheduled = RouteScheduler.schedule(stops)
        let arrival = try XCTUnwrap(scheduled[1].scheduledArrival)
        XCTAssertEqual(arrival, date(2, RouteScheduler.defaultDayStartHour))
    }

    // MARK: Multi-day routes

    func testASecondDayResetsTheClockRatherThanContinuingFromTheFirst() throws {
        let day1 = date(0, 0)
        let day2 = date(1, 0)
        let stops = [
            stop(.start),
            stop(.pickup, day: day1, windowStart: date(0, 9), serviceDurationMinutes: 30, travelTime: 3600),
            stop(.dropoff, day: day1, serviceDurationMinutes: 30, travelTime: 3600),
            // Even though day 1 ran until the evening, day 2 starts fresh at 8am.
            stop(.pickup, day: day2, travelTime: 1800),
        ]

        let scheduled = RouteScheduler.schedule(stops)

        let day1DropoffDeparture = try XCTUnwrap(scheduled[2].scheduledDeparture)
        XCTAssertTrue(calendar.isDate(day1DropoffDeparture, inSameDayAs: day1))

        let day2Arrival = try XCTUnwrap(scheduled[3].scheduledArrival)
        XCTAssertEqual(day2Arrival, date(1, RouteScheduler.defaultDayStartHour))
    }

    // MARK: Waiting for a window

    func testArrivingBeforeAWindowOpensWaitsRatherThanArrivingEarly() throws {
        let day = date(0, 0)
        let windowStart = date(0, 13)
        let stops = [
            stop(.start),
            // 8am day start + 1hr travel = 9am, well before the 1pm window.
            stop(.pickup, day: day, windowStart: windowStart, travelTime: 3600),
        ]

        let scheduled = RouteScheduler.schedule(stops)
        XCTAssertEqual(try XCTUnwrap(scheduled[1].scheduledArrival), windowStart)
    }

    // MARK: Service time propagation

    func testServiceDurationPushesBackEveryStopAfterIt() throws {
        let day = date(0, 0)
        let stops = [
            stop(.start),
            stop(.pickup, day: day, serviceDurationMinutes: 45, travelTime: 3600),
            stop(.dropoff, day: day, serviceDurationMinutes: 20, travelTime: 1800),
        ]

        let scheduled = RouteScheduler.schedule(stops)

        let pickupArrival = try XCTUnwrap(scheduled[1].scheduledArrival)
        let pickupDeparture = try XCTUnwrap(scheduled[1].scheduledDeparture)
        XCTAssertEqual(pickupDeparture, pickupArrival.addingTimeInterval(45 * 60))

        let dropoffArrival = try XCTUnwrap(scheduled[2].scheduledArrival)
        XCTAssertEqual(dropoffArrival, pickupDeparture.addingTimeInterval(1800))
    }

    // MARK: Late-deadline warnings

    func testArrivingAfterTheDeadlineIsMarkedLate() throws {
        let day = date(0, 0)
        let deadline = date(0, 8, 30)
        let stops = [
            stop(.start),
            // 8am day start + 1hr travel = 9am, after the 8:30 deadline.
            stop(.pickup, day: day, deadline: deadline, travelTime: 3600),
        ]

        let scheduled = RouteScheduler.schedule(stops)
        XCTAssertTrue(scheduled[1].isLate)
    }

    func testArrivingBeforeTheDeadlineIsNotLate() throws {
        let day = date(0, 0)
        let deadline = date(0, 17)
        let stops = [
            stop(.start),
            stop(.pickup, day: day, deadline: deadline, travelTime: 3600),
        ]

        let scheduled = RouteScheduler.schedule(stops)
        XCTAssertFalse(scheduled[1].isLate)
    }

    func testNoDeadlineIsNeverLate() {
        let day = date(0, 0)
        let stops = [
            stop(.start),
            stop(.pickup, day: day, travelTime: 999_999),
        ]

        let scheduled = RouteScheduler.schedule(stops)
        XCTAssertFalse(scheduled[1].isLate)
    }
}
