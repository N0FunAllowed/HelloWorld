import Foundation

enum Format {
    static func miles(_ meters: Double) -> String {
        let measurement = Measurement(value: meters, unit: UnitLength.meters)
        return measurement.formatted(
            .measurement(width: .abbreviated, usage: .road)
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

    static func perMile(_ amount: Double) -> String {
        "\(amount.formatted(.currency(code: currencyCode).precision(.fractionLength(2))))/mi"
    }

    static func percent(_ fraction: Double) -> String {
        fraction.formatted(.percent.precision(.fractionLength(0)))
    }

    private static var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }
}
