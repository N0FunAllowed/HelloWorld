import Foundation
import CoreLocation
import MapKit
import Observation

/// Live address suggestions from Apple Maps while typing, so an address can be
/// confirmed as a real place before it's saved.
@MainActor
@Observable
final class AddressCompleter: NSObject, MKLocalSearchCompleterDelegate {
    private(set) var suggestions: [MKLocalSearchCompletion] = []

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func update(query: String) {
        let trimmed = query.trimmed
        // Below a few characters the suggestions are noise.
        guard trimmed.count >= 3 else {
            suggestions = []
            return
        }
        completer.queryFragment = trimmed
    }

    func clear() {
        suggestions = []
    }

    /// Turns a suggestion into a real map item with a coordinate.
    func resolve(_ suggestion: MKLocalSearchCompletion) async -> MKMapItem? {
        let search = MKLocalSearch(request: MKLocalSearch.Request(completion: suggestion))
        return try? await search.start().mapItems.first
    }

    // MKLocalSearchCompleter calls its delegate on the main thread.
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        MainActor.assumeIsolated {
            suggestions = completer.results
        }
    }

    nonisolated func completer(
        _ completer: MKLocalSearchCompleter,
        didFailWithError error: Error
    ) {
        MainActor.assumeIsolated {
            suggestions = []
        }
    }
}
