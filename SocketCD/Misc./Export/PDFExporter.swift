//
//  PDFExporter.swift
//  SocketCD
//
//  Created by Justin Risner on 7/25/25.
//

import SwiftUI

enum PDFPaperSize {
    case usLetter
    case a4

    var size: CGSize {
        switch self {
        case .usLetter: return CGSize(width: 612, height: 792)
        case .a4:       return CGSize(width: 595, height: 842)
        }
    }
    
    var rect: CGRect {
        CGRect(origin: .zero, size: size)
    }
}

struct PDFExporter {
    static func export(vehicle: Vehicle, paperSize: PDFPaperSize) -> URL? {
        let settings = AppSettings()
        
        let pageRect = paperSize.rect
        let fileName = "\(vehicle.name) Records.pdf"
        let tempDirectory = NSTemporaryDirectory()
        let fileURL = URL(fileURLWithPath: tempDirectory, isDirectory: true).appendingPathComponent(fileName)
        
        // MARK: - Paragraph Styles
        let noteParagraph = NSMutableParagraphStyle()
        noteParagraph.firstLineHeadIndent = 20
        noteParagraph.headIndent = 20
        noteParagraph.paragraphSpacing = 2

        let bulletParagraph = NSMutableParagraphStyle()
        bulletParagraph.firstLineHeadIndent = 10
        bulletParagraph.headIndent = 10
        bulletParagraph.paragraphSpacing = 2

        let rightAlignParagraph = NSMutableParagraphStyle()
        rightAlignParagraph.alignment = .right

        // MARK: - Text Attributes
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 15, weight: .semibold)
        ]

        let metadataAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.darkGray
        ]

        let sectionHeaderAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 13)
        ]

        let odometerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.gray
        ]

        let bulletAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .paragraphStyle: bulletParagraph
        ]

        let noteAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.italicSystemFont(ofSize: 11),
            .paragraphStyle: noteParagraph,
            .foregroundColor: UIColor.darkGray
        ]

        let exportDateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.gray,
            .paragraphStyle: rightAlignParagraph
        ]
        
        // MARK: - Document Content
        let fullText = NSMutableAttributedString()
        
        // Export date (top-right)
        fullText.append(NSAttributedString(
            string: "\(Date.now.formatted(date: .abbreviated, time: .omitted))\n\n",
            attributes: exportDateAttributes
        ))

        // Title
        fullText.append(NSAttributedString(string: "Maintenance & Repairs\n", attributes: titleAttributes))
        fullText.append(NSAttributedString(string: "Vehicle: \(vehicle.name)\n", attributes: metadataAttributes))
        fullText.append(NSAttributedString(string: "Odometer: \(vehicle.odometer.formatted()) \(settings.distanceUnit.abbreviated)\n\n—\n\n", attributes: metadataAttributes))

        // Loop over grouped timeline
        for (date, entries) in vehicle.groupedServiceAndRepairTimeline {
            let formattedDate = date.formatted(date: .long, time: .omitted)
            let odometer = entries.first?.odometer.formatted() ?? "—"
            
            // Section header: date
            fullText.append(NSAttributedString(string: "\(formattedDate)\n", attributes: sectionHeaderAttributes))
            fullText.append(NSAttributedString(string: "Odometer: \(odometer) \(settings.distanceUnit.abbreviated)\n", attributes: odometerAttributes))
            
            for entry in entries {
                switch entry.type {
                case .service(let record):
                    let name = record.service?.name ?? "Service"
                    fullText.append(NSAttributedString(string: "• \(name)\n", attributes: bulletAttributes))

                    let note = record.note.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !note.isEmpty {
                        fullText.append(NSAttributedString(string: "\(note)\n", attributes: noteAttributes))
                    }

                case .repair(let repair):
                    let name = repair.name
                    fullText.append(NSAttributedString(string: "• \(name)\n", attributes: bulletAttributes))

                    let note = repair.note.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !note.isEmpty {
                        fullText.append(NSAttributedString(string: "\(note)\n", attributes: noteAttributes))
                    }
                }
            }

            fullText.append(NSAttributedString(string: "\n")) // extra space between groups
        }

        // MARK: - PDF Generation
        let formatter = UISimpleTextPrintFormatter(attributedText: fullText)
        let renderer = UIPrintPageRenderer()
        renderer.addPrintFormatter(formatter, startingAtPageAt: 0)

        // Set page size and margins
        renderer.setValue(NSValue(cgRect: pageRect), forKey: "paperRect")
        let printableRect = pageRect.inset(by: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50))
        renderer.setValue(NSValue(cgRect: printableRect), forKey: "printableRect")

        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, .zero, nil)

        for i in 0..<renderer.numberOfPages {
            UIGraphicsBeginPDFPage()
            renderer.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
        }

        UIGraphicsEndPDFContext()

        // Save to temporary directory
        do {
            try pdfData.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to write PDF: \(error)")
            return nil
        }
    }

}
