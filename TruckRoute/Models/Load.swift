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

    init(
        reference: String = "",
        pickup: Place? = nil,
        dropoff: Place? = nil,
        pickupDate: Date = .now,
        deliveryDate: Date? = nil,
        notes: String = ""
    ) {
        self.reference = reference
        self.pickup = pickup
        self.dropoff = dropoff
        self.pickupDate = pickupDate
        self.deliveryDate = deliveryDate
        self.notes = notes
    }

    var displayName: String {
        if !reference.isEmpty { return reference }
        let from = pickup?.displayName ?? "?"
        let to = dropoff?.displayName ?? "?"
        return "\(from) → \(to)"
    }
}
