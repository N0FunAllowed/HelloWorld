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
    /// Delivered loads are done — kept for the record, but out of the way of
    /// both the working list and route planning.
    var isDelivered: Bool

    init(
        reference: String = "",
        pickup: Place? = nil,
        dropoff: Place? = nil,
        pickupDate: Date = .now,
        deliveryDate: Date? = nil,
        notes: String = "",
        rate: Double? = nil,
        isDelivered: Bool = false
    ) {
        self.reference = reference
        self.pickup = pickup
        self.dropoff = dropoff
        self.pickupDate = pickupDate
        self.deliveryDate = deliveryDate
        self.notes = notes
        self.rate = rate
        self.isDelivered = isDelivered
    }

    var displayName: String {
        if !reference.isEmpty { return reference }
        let from = pickup?.displayName ?? "?"
        let to = dropoff?.displayName ?? "?"
        return "\(from) → \(to)"
    }
}
