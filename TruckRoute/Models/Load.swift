import Foundation
import CoreLocation
import SwiftData

@Model
final class Load {
    var reference: String
    var pickupAddress: String
    var dropoffAddress: String
    var pickupDate: Date
    var deliveryDate: Date?
    var notes: String

    // Cached geocoding results so a route replan doesn't re-hit CLGeocoder.
    var pickupLatitude: Double?
    var pickupLongitude: Double?
    var dropoffLatitude: Double?
    var dropoffLongitude: Double?

    init(
        reference: String = "",
        pickupAddress: String = "",
        dropoffAddress: String = "",
        pickupDate: Date = .now,
        deliveryDate: Date? = nil,
        notes: String = ""
    ) {
        self.reference = reference
        self.pickupAddress = pickupAddress
        self.dropoffAddress = dropoffAddress
        self.pickupDate = pickupDate
        self.deliveryDate = deliveryDate
        self.notes = notes
    }

    var pickupCoordinate: CLLocationCoordinate2D? {
        get { Self.coordinate(pickupLatitude, pickupLongitude) }
        set {
            pickupLatitude = newValue?.latitude
            pickupLongitude = newValue?.longitude
        }
    }

    var dropoffCoordinate: CLLocationCoordinate2D? {
        get { Self.coordinate(dropoffLatitude, dropoffLongitude) }
        set {
            dropoffLatitude = newValue?.latitude
            dropoffLongitude = newValue?.longitude
        }
    }

    var displayName: String {
        reference.isEmpty ? "\(pickupAddress) → \(dropoffAddress)" : reference
    }

    private static func coordinate(_ lat: Double?, _ lon: Double?) -> CLLocationCoordinate2D? {
        guard let lat, let lon else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}
