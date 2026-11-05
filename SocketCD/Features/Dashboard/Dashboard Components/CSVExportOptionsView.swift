import SwiftUI

struct CSVExportOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var options = CSVExportOptions()

    let export: (CSVExportOptions) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Maintenance", isOn: $options.includeMaintenance)
                    Toggle("Repairs", isOn: $options.includeRepairs)
                    Toggle("Fill-ups", isOn: $options.includeFillups)
                } header: {
                    Text("Data to Export")
                } footer: {
                    Text("Each selection is exported as a separate spreadsheet.")
                }
            }
            .navigationTitle("CSV Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") { dismiss() }
                        .labelStyle(.adaptive)
                        .adaptiveTint()
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Export", systemImage: "checkmark") {
                        export(options)
                        dismiss()
                    }
                    .labelStyle(.adaptive)
                    .disabled(!options.hasSelection)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
