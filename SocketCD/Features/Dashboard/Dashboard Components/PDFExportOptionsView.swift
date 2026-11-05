import SwiftUI

struct PDFExportOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("pdfExportPaperSize") private var paperSizeRawValue = PDFPaperSize.usLetter.rawValue
    @State private var options = PDFExportOptions()

    let export: (PDFExportOptions) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Picker("Paper Size", selection: paperSizeSelection) {
                    ForEach(PDFPaperSize.allCases) { paperSize in
                        Text(paperSize.title).tag(paperSize)
                    }
                }

                Section("Include in Report") {
                    Toggle("Costs", isOn: $options.includeCosts)
                    Toggle("Notes", isOn: $options.includeNotes)
                    Toggle("Attachments", isOn: attachmentsSelection)
                }
            }
            .navigationTitle("PDF Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") { dismiss() }
                        .labelStyle(.adaptive)
                        .adaptiveTint()
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Export", systemImage: "checkmark") {
                        var selectedOptions = options
                        selectedOptions.paperSize = selectedPaperSize
                        dismiss()
                        export(selectedOptions)
                    }
                    .labelStyle(.adaptive)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var attachmentsSelection: Binding<Bool> {
        Binding(
            get: { options.includePhotos && options.includePDFDocuments },
            set: {
                options.includePhotos = $0
                options.includePDFDocuments = $0
            }
        )
    }

    private var selectedPaperSize: PDFPaperSize {
        PDFPaperSize(rawValue: paperSizeRawValue) ?? .usLetter
    }

    private var paperSizeSelection: Binding<PDFPaperSize> {
        Binding(
            get: { selectedPaperSize },
            set: { paperSizeRawValue = $0.rawValue }
        )
    }
}
