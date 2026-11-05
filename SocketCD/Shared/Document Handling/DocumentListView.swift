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
                LabeledContent {
                    DiscardButton("Remove \(document.fileName)") {
                        withAnimation {
                            delete(document)
                        }
                    }
                } label: {
                    RowLabel(document: document)
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

private struct RowLabel: View {
    let document: AttachedDocument
    
    var body: some View {
        Label {
            Text(document.fileName)
                .lineLimit(1)
        } icon: {
            Image(systemName: "document")
                .foregroundStyle(.secondary)
        }
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
            RowLabel(document: document)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
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
