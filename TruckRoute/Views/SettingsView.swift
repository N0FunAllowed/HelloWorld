import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query(sort: \Place.name) private var places: [Place]

    private var homeBase: Place? {
        places.first(where: \.isHomeBase)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if places.isEmpty {
                        Text("Add an address first, on the Addresses tab.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(places) { place in
                            Button {
                                setHomeBase(place)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(place.displayName).foregroundStyle(.primary)
                                        Text(place.address)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if place.isHomeBase {
                                        Image(systemName: "checkmark").foregroundStyle(.tint)
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    Text("Home base")
                } footer: {
                    Text(
                        homeBase == nil
                            ? "Pick the yard every route starts from."
                            : "Every route starts from \(homeBase?.displayName ?? "")."
                    )
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func setHomeBase(_ place: Place) {
        for other in places where other.isHomeBase {
            other.isHomeBase = false
        }
        place.isHomeBase = true
    }
}
