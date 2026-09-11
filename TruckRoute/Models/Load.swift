import Foundation
import SwiftData

@Model
final class Load {
    var reference: String
    var pickup: Place?
    var dropoff: Place?
    var pickupDate: Date
    var deliveryDate: Date?
    var notes: String
    /// What the load pays, before any costs. Nil when it isn't known yet.
    var rate: Double?
    /// Estimated operating costs for this individual load. Existing loads
    /// safely start at zero when the model is migrated.
    var fuelCost: Double = 0
    var tollCost: Double = 0
    var permitCost: Double = 0
    var driverPay: Double = 0
    var otherCost: Double = 0

    init(
        reference: String = "",
        pickup: Place? = nil,
        dropoff: Place? = nil,
        pickupDate: Date = .now,
        deliveryDate: Date? = nil,
        notes: String = "",
        rate: Double? = nil,
        fuelCost: Double = 0,
        tollCost: Double = 0,
        permitCost: Double = 0,
        driverPay: Double = 0,
        otherCost: Double = 0
    ) {
        self.reference = reference
        self.pickup = pickup
        self.dropoff = dropoff
        self.pickupDate = pickupDate
        self.deliveryDate = deliveryDate
        self.notes = notes
        self.rate = rate
        self.fuelCost = fuelCost
        self.tollCost = tollCost
        self.permitCost = permitCost
        self.driverPay = driverPay
        self.otherCost = otherCost
    }

    var displayName: String {
        if !reference.isEmpty { return reference }
        let from = pickup?.displayName ?? "?"
        let to = dropoff?.displayName ?? "?"
        return "\(from) → \(to)"
    }

    var totalCost: Double {
        fuelCost + tollCost + permitCost + driverPay + otherCost
    }

    /// Nil until the load's payment is known.
    var profit: Double? {
        rate.map { $0 - totalCost }
    }

    var profitMargin: Double? {
        guard let rate, rate > 0, let profit else { return nil }
        return profit / rate
    }
}
