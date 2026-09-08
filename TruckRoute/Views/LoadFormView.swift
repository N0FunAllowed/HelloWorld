import SwiftUI
import SwiftData

struct LoadFormView: View {
    /// Nil when adding a new load.
    let load: Load?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var reference = ""
    @State private var pickupAddress = ""
    @State private var dropoffAddress = ""
    @State private var pickupDate = Date.now
    @State private var hasDeliveryDate = false
    @State private var deliveryDate = Date.now
    @State private var notes = ""

    private var canSave: Bool {
        !pickupAddress.trimmed.isEmpty && !dropoffAddress.trimmed.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Route") {
                    TextField("Pick up at", text: $pickupAddress, axis: .vertical)
                    TextField("Drop off at", text: $dropoffAddress, axis: .vertical)
                }
                .textInputAutocapitalization(.words)

                Section("Schedule") {
                    DatePicker("Pickup", selection: $pickupDate)
                    Toggle("Delivery deadline", isOn: $hasDeliveryDate.animation())
                    if hasDeliveryDate {
                        DatePicker("Deliver by", selection: $deliveryDate)
                    }
                }

                Section("Details") {
                    TextField("Reference or customer", text: $reference)
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
        pickupAddress = load.pickupAddress
        dropoffAddress = load.dropoffAddress
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

        // A changed address invalidates the cached coordinate.
        if target.pickupAddress != pickupAddress.trimmed {
            target.pickupCoordinate = nil
        }
        if target.dropoffAddress != dropoffAddress.trimmed {
            target.dropoffCoordinate = nil
        }

        target.reference = reference.trimmed
        target.pickupAddress = pickupAddress.trimmed
        target.dropoffAddress = dropoffAddress.trimmed
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
