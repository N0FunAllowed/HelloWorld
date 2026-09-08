import SwiftUI

struct SettingsView: View {
    @AppStorage("homeBase") private var homeBase = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Yard address", text: $homeBase, axis: .vertical)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Home base")
                } footer: {
                    Text("Every route starts here.")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
