import SwiftUI
import SwiftData

struct LoadListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Load.pickupDate) private var loads: [Load]
    @State private var editing: Load?
    @State private var isAdding = false

    var body: some View {
        NavigationStack {
            Group {
                if loads.isEmpty {
                    ContentUnavailableView(
                        "No loads yet",
                        systemImage: "shippingbox",
                        description: Text("Add this week's loads and the Route tab will order them for you.")
                    )
                } else {
                    list
                }
            }
            .navigationTitle("Loads")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add load", systemImage: "plus") { isAdding = true }
                }
            }
            .sheet(isPresented: $isAdding) {
                LoadFormView(load: nil)
            }
            .sheet(item: $editing) { load in
                LoadFormView(load: load)
            }
        }
    }

    private var list: some View {
        List {
            ForEach(groupedByDay, id: \.day) { group in
                Section(Format.day(group.day)) {
                    ForEach(group.loads) { load in
                        Button {
                            editing = load
                        } label: {
                            LoadRow(load: load)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            context.delete(group.loads[index])
                        }
                    }
                }
            }
        }
    }

    private var groupedByDay: [(day: Date, loads: [Load])] {
        let calendar = Calendar.current
        return Dictionary(grouping: loads) { calendar.startOfDay(for: $0.pickupDate) }
            .map { (day: $0.key, loads: $0.value.sorted { $0.pickupDate < $1.pickupDate }) }
            .sorted { $0.day < $1.day }
    }
}

private struct LoadRow: View {
    let load: Load

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !load.reference.isEmpty {
                Text(load.reference).font(.headline)
            }
            Label(load.pickup?.displayName ?? "No pickup set", systemImage: "arrow.up.circle")
            Label(load.dropoff?.displayName ?? "No drop-off set", systemImage: "arrow.down.circle")
            HStack(spacing: 6) {
                Text(load.pickupDate.formatted(date: .omitted, time: .shortened))
                if let rate = load.rate {
                    Text(Format.money(rate)).foregroundStyle(.green)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .font(.subheadline)
    }
}
