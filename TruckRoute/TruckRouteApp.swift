import SwiftUI
import SwiftData

@main
struct TruckRouteApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Load.self, Place.self])
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            LoadListView()
                .tabItem { Label("Loads", systemImage: "shippingbox") }
            RouteView()
                .tabItem { Label("Route", systemImage: "map") }
            PlaceListView()
                .tabItem { Label("Addresses", systemImage: "book.closed") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}
