import SwiftUI
import SwiftData
import MapKit

struct RouteView: View {
    @Query(sort: \Load.pickupDate) private var loads: [Load]
    @Query private var places: [Place]
    @State private var planner = RoutePlanner()

    private var homeBase: Place? {
        places.first(where: \.isHomeBase)
    }

    var body: some View {
        NavigationStack {
            Group {
                if homeBase == nil {
                    ContentUnavailableView(
                        "Set your home base",
                        systemImage: "house",
                        description: Text("The route starts from your yard. Pick it in Settings.")
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
                Text("\(route.workingStopCount) stops")
            } footer: {
                RouteSummary(route: route)
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
        guard let homeBase else { return }
        Task { await planner.plan(loads: loads, from: homeBase) }
    }
}

private struct RouteSummary: View {
    let route: PlannedRoute

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("\(Format.miles(route.totalDistance)) · \(Format.duration(route.totalTravelTime)) driving")
            if route.emptyDistance > 0, let share = route.deadheadShare {
                Text("\(Format.miles(route.loadedDistance)) loaded · \(Format.miles(route.emptyDistance)) empty (\(Format.percent(share)) deadhead)")
            }
            if let total = route.totalRate, let perMile = route.ratePerMile {
                Text("\(Format.money(total)) · \(Format.perMile(perMile)) all miles")
                    .fontWeight(.semibold)
            }
            if let cost = route.totalCost {
                Text("Costs \(Format.money(cost))")
                    .foregroundStyle(.secondary)
            }
            if let profit = route.totalProfit {
                Text(route.profitMargin.map { "Profit \(Format.money(profit)) · \(Format.percent($0)) margin" }
                    ?? "Profit \(Format.money(profit))")
                    .fontWeight(.semibold)
                    .foregroundStyle(profit >= 0 ? .green : .red)
            }
        }
    }
}

private struct RouteStopRow: View {
    let index: Int
    let stop: RouteStop

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let travelTime = stop.travelTime, let distance = stop.distance {
                HStack(spacing: 4) {
                    if stop.isDeadheadLeg {
                        Image(systemName: "arrow.right.to.line")
                        Text("Empty \(Format.miles(distance)) · \(Format.duration(travelTime))")
                    } else {
                        Text("Loaded \(Format.miles(distance)) · \(Format.duration(travelTime))")
                    }
                }
                .font(.caption)
                .foregroundStyle(stop.isDeadheadLeg ? Color.orange : Color.secondary)
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
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(stop.placeName).font(.subheadline.bold())
                    Text(stop.address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let day = stop.day {
                        Text(Format.day(day))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let rate = stop.loadRate, stop.kind == .dropoff {
                        Text(stop.ratePerMile.map { "\(Format.money(rate)) · \(Format.perMile($0))" }
                            ?? Format.money(rate))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                        if let cost = stop.loadCost {
                            Text("Cost \(Format.money(cost))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
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
        case .start, .end: .gray
        case .pickup: .blue
        case .dropoff: .green
        }
    }

    private func openInMaps() {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: stop.coordinate))
        item.name = stop.placeName.isEmpty ? stop.address : stop.placeName
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}
