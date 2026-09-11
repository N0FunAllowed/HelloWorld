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
    @State private var rateText = ""
    @State private var fuelCostText = ""
    @State private var tollCostText = ""
    @State private var permitCostText = ""
    @State private var driverPayText = ""
    @State private var otherCostText = ""

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

                Section {
                    TextField("Rate", text: $rateText)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Pay")
                } footer: {
                    Text("What the load pays. The route works out your rate per mile across loaded and empty miles.")
                }

                Section("Estimated costs") {
                    MoneyField("Fuel", text: $fuelCostText)
                    MoneyField("Tolls", text: $tollCostText)
                    MoneyField("Permits", text: $permitCostText)
                    MoneyField("Driver pay", text: $driverPayText)
                    MoneyField("Other", text: $otherCostText)
                } footer: {
                    Text("Costs are estimates for this load. Profit is payment minus these costs.")
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
        if let rate = load.rate {
            rateText = rate.formatted(.number.precision(.fractionLength(0...2)))
        }
        fuelCostText = load.fuelCost.moneyText
        tollCostText = load.tollCost.moneyText
        permitCostText = load.permitCost.moneyText
        driverPayText = load.driverPay.moneyText
        otherCostText = load.otherCost.moneyText
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
        target.rate = rateText.moneyValue
        target.fuelCost = fuelCostText.moneyValue ?? 0
        target.tollCost = tollCostText.moneyValue ?? 0
        target.permitCost = permitCostText.moneyValue ?? 0
        target.driverPay = driverPayText.moneyValue ?? 0
        target.otherCost = otherCostText.moneyValue ?? 0

        dismiss()
    }
}

private struct MoneyField: View {
    let title: String
    @Binding var text: String

    init(_ title: String, text: Binding<String>) {
        self.title = title
        _text = text
    }

    var body: some View {
        TextField(title, text: $text)
            .keyboardType(.decimalPad)
    }
}

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Tolerates values such as "$2,400" and blank values.
    var moneyValue: Double? {
        let digits = filter { $0.isNumber || $0 == "." }
        return digits.isEmpty ? nil : Double(digits)
    }
}

private extension Double {
    var moneyText: String {
        formatted(.number.precision(.fractionLength(0...2)))
    }
}
