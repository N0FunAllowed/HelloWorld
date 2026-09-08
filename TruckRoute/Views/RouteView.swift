import SwiftUI
import SwiftData
import MapKit

struct RouteView: View {
    @Query(sort: \Load.pickupDate) private var loads: [Load]
    @AppStorage("homeBase") private var homeBase = ""
    @State private var planner = RoutePlanner()

    var body: some View {
        NavigationStack {
            Group {
                if homeBase.trimmed.isEmpty {
                    ContentUnavailableView(
                        "Set your home base",
                        systemImage: "house",
                        description: Text("The route starts from your yard. Add its address in Settings.")
                    )
                } else if loads.isEmpty {
                    ContentUnavailableView(
                        "Nothing to route",
                        systemImage: "map",
                        description: Text("Add some loads first.")
                    )
                } else if let route = planner.route {
                    routeDetail(route)
                } else {
                    ContentUnavailableView {
                        Label("No route yet", systemImage: "map")
                    } description: {
                        Text("Plan a route for the \(loads.count) load\(loads.count == 1 ? "" : "s") on the board.")
                    } actions: {
                        Button("Plan route", action: planRoute)
                            .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("Route")
            .toolbar {
                if planner.route != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Replan", systemImage: "arrow.clockwise", action: planRoute)
                            .disabled(planner.isPlanning)
                    }
                }
            }
            .overlay {
                if planner.isPlanning {
                    ProgressView(planner.progressNote ?? "Planning…")
                        .padding()
                        .background(.regularMaterial, in: .rect(cornerRadius: 12))
                }
            }
            .alert(
                "Couldn't plan the route",
                isPresented: .constant(planner.errorMessage != nil)
            ) {
                Button("OK") { planner.clear() }
            } message: {
                Text(planner.errorMessage ?? "")
            }
        }
    }

    private func routeDetail(_ route: PlannedRoute) -> some View {
        List {
            Section {
                RouteMapView(stops: route.stops)
                    .frame(height: 260)
                    .listRowInsets(EdgeInsets())
            }

            Section {
                ForEach(Array(route.stops.enumerated()), id: \.element.id) { index, stop in
                    RouteStopRow(index: index, stop: stop)
                }
            } header: {
                Text("\(route.stops.count - 1) stops")
            } footer: {
                Text("\(Format.miles(route.totalDistance)) · \(Format.duration(route.totalTravelTime)) driving")
            }

            if !route.skipped.isEmpty {
                Section("Left out") {
                    ForEach(route.skipped) { skipped in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(skipped.reference).font(.subheadline.bold())
                            Text(skipped.reason)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func planRoute() {
        Task { await planner.plan(loads: loads, startingFrom: homeBase.trimmed) }
    }
}

private struct RouteStopRow: View {
    let index: Int
    let stop: RouteStop

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let travelTime = stop.travelTime, let distance = stop.distance {
                Text("Drive \(Format.miles(distance)) · \(Format.duration(travelTime))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if index > 0 {
                Text("No driving route found")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("\(index)")
                    .font(.caption.monospacedDigit().bold())
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(color, in: .circle)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(stop.kind.label)\(stop.loadReference.map { " · \($0)" } ?? "")")
                        .font(.subheadline.bold())
                    Text(stop.address).font(.subheadline)
                    if let day = stop.day {
                        Text(Format.day(day))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button("Directions", systemImage: "arrow.triangle.turn.up.right.circle") {
                    openInMaps()
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .foregroundStyle(.tint)
            }
        }
        .padding(.vertical, 2)
    }

    private var color: Color {
        switch stop.kind {
        case .start: .gray
        case .pickup: .blue
        case .dropoff: .green
        }
    }

    private func openInMaps() {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: stop.coordinate))
        item.name = stop.address
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}
