import Foundation

enum Format {
    /// The chosen unit rather than the locale's road units, so a distance
    /// never disagrees with the "/mi" or "/km" on the rate beside it.
    static func distance(_ meters: Double, in unit: DistanceUnit) -> String {
        let converted = Measurement(value: meters, unit: UnitLength.meters)
            .converted(to: unit.unitLength)
        return converted.formatted(
            .measurement(
                width: .abbreviated,
                usage: .asProvided,
                numberFormatStyle: .number.precision(.fractionLength(0))
            )
        )
    }

    static func duration(_ seconds: TimeInterval) -> String {
        Duration.seconds(seconds).formatted(
            .units(allowed: [.hours, .minutes], width: .abbreviated)
        )
    }

    static func day(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.wide).month().day())
    }

    static func money(_ amount: Double) -> String {
        amount.formatted(.currency(code: currencyCode).precision(.fractionLength(0)))
    }

    static func rate(_ amount: Double, per unit: DistanceUnit) -> String {
        let money = amount.formatted(.currency(code: currencyCode).precision(.fractionLength(2)))
        return "\(money)/\(unit.abbreviation)"
    }

    static func percent(_ fraction: Double) -> String {
        fraction.formatted(.percent.precision(.fractionLength(0)))
    }

    private static var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }
}
