//
//  DocumentListView.swift
//  SocketCD
//

import CoreData
import PDFKit
import SwiftUI

struct DocumentListView: View {
    @Binding var documents: [AttachedDocument]
    let isEditable: Bool

    var body: some View {
        ForEach(documents.sorted { $0.timeStamp < $1.timeStamp }, id: \.objectID) { document in
            if isEditable {
                HStack {
                    Label(document.fileName, systemImage: "document")
                        .labelStyle(.titleOnly)
                        .lineLimit(1)

                    Spacer()

                    Button("Delete Document", systemImage: "xmark.circle.fill") {
                        delete(document)
                    }
                    .buttonStyle(.plain)
                    .labelStyle(.iconOnly)
                    .font(.title2)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .gray)
                }
            } else {
                ReadOnlyDocumentRow(document: document)
            }
        }
    }

    private func delete(_ document: AttachedDocument) {
        documents.removeAll { $0.objectID == document.objectID }
    }
}

private struct ReadOnlyDocumentRow: View {
    let document: AttachedDocument

    @State private var previewItem: DocumentPreviewItem?
    @State private var showingPreviewError = false

    var body: some View {
        Button {
            preview()
        } label: {
            Label(document.fileName, systemImage: "document")
                .lineLimit(1)
                .tint(.primary)
        }
        .fullScreenCover(item: $previewItem) { item in
            ReadOnlyDocumentPreview(
                document: item.document,
                documentData: item.documentData,
                title: item.title
            ) {
                previewItem = nil
            }
        }
        .alert("Preview Error", isPresented: $showingPreviewError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("There was a problem opening that document.")
        }
    }

    private func preview() {
        guard let pdfDocument = PDFDocument(data: document.documentData) else {
            showingPreviewError = true
            return
        }

        previewItem = DocumentPreviewItem(
            document: pdfDocument,
            documentData: document.documentData,
            title: document.fileName
        )
    }
}

private struct DocumentPreviewItem: Identifiable {
    let id = UUID()
    let document: PDFDocument
    let documentData: Data
    let title: String
}
