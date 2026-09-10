import SwiftUI
import SwiftData

struct LoadFormView: View {
    /// Nil when adding a new load.
    let load: Load?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var reference = ""
    @State private var pickup: Place?
    @State private var dropoff: Place?
    @State private var pickupDate = Date.now
    @State private var hasDeliveryDate = false
    @State private var deliveryDate = Date.now
    @State private var notes = ""

    private var canSave: Bool { pickup != nil && dropoff != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Route") {
                    NavigationLink {
                        PlacePicker(title: "Pick Up At", selection: $pickup)
                    } label: {
                        PlaceRowLabel(role: "Pick up at", place: pickup)
                    }
                    NavigationLink {
                        PlacePicker(title: "Drop Off At", selection: $dropoff)
                    } label: {
                        PlaceRowLabel(role: "Drop off at", place: dropoff)
                    }
                }

                Section("Schedule") {
                    DatePicker("Pickup", selection: $pickupDate)
                    Toggle("Delivery deadline", isOn: $hasDeliveryDate.animation())
                    if hasDeliveryDate {
                        DatePicker("Deliver by", selection: $deliveryDate)
                    }
                }

                Section("Details") {
                    TextField("Reference or customer", text: $reference)
                        .textInputAutocapitalization(.words)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...)
                }

                if let load {
                    Section {
                        Button("Delete load", role: .destructive) {
                            context.delete(load)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(load == nil ? "New Load" : "Edit Load")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(!canSave)
                }
            }
            .onAppear(perform: loadExisting)
        }
    }

    private func loadExisting() {
        guard let load else { return }
        reference = load.reference
        pickup = load.pickup
        dropoff = load.dropoff
        pickupDate = load.pickupDate
        notes = load.notes
        if let delivery = load.deliveryDate {
            hasDeliveryDate = true
            deliveryDate = delivery
        }
    }

    private func save() {
        let target = load ?? {
            let new = Load()
            context.insert(new)
            return new
        }()

        target.reference = reference.trimmed
        target.pickup = pickup
        target.dropoff = dropoff
        target.pickupDate = pickupDate
        target.deliveryDate = hasDeliveryDate ? deliveryDate : nil
        target.notes = notes

        dismiss()
    }
}

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
