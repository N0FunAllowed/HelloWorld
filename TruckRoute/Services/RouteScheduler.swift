import Foundation

/// Walks a planned route's stops in order and works out when the truck is
/// scheduled to reach and leave each one.
///
/// This is a pure, synchronous function over `[RouteStop]` — it needs
/// nothing from MapKit or the network, only each stop's already-measured
/// `travelTime`. That's deliberate: it's the one piece of the route planner
/// worth unit-testing directly, without standing up a live directions call
/// for every scenario.
enum RouteScheduler {
    /// When a working day starts if nothing says otherwise.
    static let defaultDayStartHour = 8

    /// Returns the same stops with `scheduledArrival`, `scheduledDeparture`
    /// and `isLate` filled in.
    ///
    /// The clock only ever advances from a stop's own `day` — never from the
    /// yard stops at either end, which carry no day of their own. That's what
    /// keeps a route whose first load is days out from being scheduled as if
    /// it started this morning: nothing anchors the clock until the first
    /// stop that actually has a day does.
    static func schedule(
        _ stops: [RouteStop],
        calendar: Calendar = .current
    ) -> [RouteStop] {
        var result = stops
        var clock: Date?

        for index in result.indices {
            var stop = result[index]
            let stopDay = stop.day.map { calendar.startOfDay(for: $0) }

            // A new operating day resets the clock to that day's start — but
            // resetting it is not a substitute for the drive to get here:
            // the two used to be an if/else, which meant the first stop of
            // any day looked like it arrived with no travel time at all and
            // could read as on-time when it was actually running late.
            if let stopDay {
                let isNewOperatingDay = clock.map { calendar.startOfDay(for: $0) != stopDay } ?? true
                if isNewOperatingDay {
                    clock = dayStart(for: stopDay, calendar: calendar)
                }
            }

            if index > 0, let travelTime = stop.travelTime, let current = clock {
                clock = current.addingTimeInterval(travelTime)
            }

            // Arriving before the window opens just means waiting for it.
            if let windowStart = stop.windowStart, let arrival = clock, arrival < windowStart {
                clock = windowStart
            }

            stop.scheduledArrival = clock

            if let deadline = stop.deadline, let arrival = clock {
                stop.isLate = arrival > deadline
            } else {
                stop.isLate = false
            }

            let departure = clock?.addingTimeInterval(TimeInterval(stop.serviceDurationMinutes * 60))
            stop.scheduledDeparture = departure
            clock = departure

            result[index] = stop
        }

        return result
    }

    private static func dayStart(for day: Date, calendar: Calendar) -> Date {
        calendar.date(
            bySettingHour: defaultDayStartHour,
            minute: 0,
            second: 0,
            of: day
        ) ?? day
    }
}
