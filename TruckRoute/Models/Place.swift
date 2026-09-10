import Foundation
import CoreLocation
import SwiftData

/// An entry in the address book. Loads point at these rather than carrying
/// their own address text, so a yard's address is typed once and its geocoded
/// coordinate is reused by every load that touches it.
@Model
final class Place {
    var name: String
    var address: String
    var notes: String
    /// Exactly one place is the yard every route starts from.
    var isHomeBase: Bool

    var latitude: Double?
    var longitude: Double?

    init(
        name: String = "",
        address: String = "",
        notes: String = "",
        isHomeBase: Bool = false
    ) {
        self.name = name
        self.address = address
        self.notes = notes
        self.isHomeBase = isHomeBase
    }

    var coordinate: CLLocationCoordinate2D? {
        get {
            guard let latitude, let longitude else { return nil }
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        set {
            latitude = newValue?.latitude
            longitude = newValue?.longitude
        }
    }

    var displayName: String {
        name.isEmpty ? address : name
    }
}
