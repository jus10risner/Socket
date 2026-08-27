//
//  ReadOnlyDocumentPreview.swift
//  SocketCD
//

import CoreTransferable
import PDFKit
import SwiftUI
import UniformTypeIdentifiers

struct ReadOnlyDocumentPreview: View {
    let document: PDFDocument
    let documentData: Data
    let title: String
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            PDFDocumentView(document: document)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem {
                        ShareLink(
                            item: PDFShareItem(data: documentData, fileName: title),
                            preview: SharePreview(
                                title,
                                image: sharePreviewImage
                            )
                        ) {
                            Label("Share Document", systemImage: "square.and.arrow.up")
                        }
                    }

                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done", systemImage: "xmark", action: onDismiss)
                    }
                }
        }
        .tint(.primary)
    }
    
    private var sharePreviewImage: Image {
        guard let firstPage = document.page(at: 0) else {
            return Image(systemName: "document")
        }

        let thumbnail = firstPage.thumbnail(
            of: CGSize(width: 600, height: 800),
            for: .cropBox
        )

        return Image(uiImage: thumbnail)
    }
}

private struct PDFShareItem: Transferable {
    let data: Data
    let fileName: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .pdf) { item in
            item.data
        }
        .suggestedFileName { item in
            let fileName = URL(fileURLWithPath: item.fileName).lastPathComponent
            return fileName.lowercased().hasSuffix(".pdf") ? fileName : "\(fileName).pdf"
        }
    }
}

private struct PDFDocumentView: UIViewRepresentable {
    let document: PDFDocument

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.displaysPageBreaks = true
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        if pdfView.document !== document {
            pdfView.document = document
            pdfView.autoScales = true
        }
    }
}
