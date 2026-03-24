//
//  PDFExporter.swift
//  SocketCD
//
//  Created by Justin Risner on 7/25/25.
//

import SwiftUI
import UIKit

enum PDFPaperSize {
    case usLetter
    case a4

    var size: CGSize {
        switch self {
        case .usLetter: return CGSize(width: 612, height: 792)
        case .a4:       return CGSize(width: 595, height: 842)
        }
    }
}

struct PDFExporter {
    static func export<Content: View>(
        view: Content,
        paperSize: PDFPaperSize = .usLetter,
        fileName: String
    ) -> URL? {
        let size = paperSize.size
        let hosting = UIHostingController(rootView: view)
        hosting.view.bounds = CGRect(origin: .zero, size: size)
        hosting.view.backgroundColor = .white

        let renderer = UIGraphicsPDFRenderer(bounds: hosting.view.bounds)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try renderer.writePDF(to: url) { context in
                context.beginPage()
                hosting.view.drawHierarchy(in: hosting.view.bounds, afterScreenUpdates: true)
            }
            return url
        } catch {
            print("PDF export failed: \(error)")
            return nil
        }
    }
}
