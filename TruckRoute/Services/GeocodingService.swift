import Foundation
import CoreLocation

enum GeocodingError: LocalizedError {
    case notFound(String)

    var errorDescription: String? {
        switch self {
        case .notFound(let address): "Couldn't find \"\(address)\" on the map."
        }
    }
}

/// Serializes CLGeocoder lookups. Apple throttles the geocoder hard and starts
/// returning errors if requests overlap or come in faster than about one per
/// second, so every lookup goes through this actor one at a time.
actor GeocodingService {
    static let shared = GeocodingService()

    private let geocoder = CLGeocoder()
    private var cache: [String: CLLocationCoordinate2D] = [:]
    private var lastRequest: Date?

    func coordinate(for address: String) async throws -> CLLocationCoordinate2D {
        let key = address.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let cached = cache[key] { return cached }

        if let lastRequest {
            let elapsed = Date.now.timeIntervalSince(lastRequest)
            if elapsed < 1 {
                try await Task.sleep(for: .seconds(1 - elapsed))
            }
        }
        lastRequest = .now

        let placemarks = try await geocoder.geocodeAddressString(address)
        guard let coordinate = placemarks.first?.location?.coordinate else {
            throw GeocodingError.notFound(address)
        }
        cache[key] = coordinate
        return coordinate
    }
}
