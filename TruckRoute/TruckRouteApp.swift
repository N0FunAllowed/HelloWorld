import SwiftUI
import SwiftData

@main
struct TruckRouteApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Load.self)
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            LoadListView()
                .tabItem { Label("Loads", systemImage: "shippingbox") }
            RouteView()
                .tabItem { Label("Route", systemImage: "map") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}
