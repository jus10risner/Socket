//
//  PDFExporter.swift
//  SocketCD
//
//  Created by Justin Risner on 7/25/25.
//

import CoreText
import ImageIO
import PDFKit
import UIKit

enum PDFPaperSize: String, CaseIterable, Identifiable {
    case usLetter
    case a4

    var id: Self { self }

    var title: String {
        switch self {
        case .usLetter: String(localized: "US Letter", comment: "PDF paper size")
        case .a4: "A4"
        }
    }

    var size: CGSize {
        switch self {
        case .usLetter: CGSize(width: 612, height: 792)
        case .a4: CGSize(width: 595, height: 842)
        }
    }
}

struct PDFExportOptions {
    var paperSize: PDFPaperSize = .usLetter
    var includePhotos = false
    var includeCosts = true
    var includeNotes = true
    var includePDFDocuments = false
}

struct PDFExporter {
    // Group by both values, while preserving each log's shared cost and attachments.
    struct TimelineEntry {
        let date: Date
        let odometer: Int
        var items: [VehicleExportRecord]
    }

    private struct TimelineKey: Hashable {
        let date: Date
        let odometer: Int
    }

    private struct Appendix {
        let key: String
        let record: VehicleExportRecord
        let documents: [AttachedDocument]
    }

    private static let pageMargin: CGFloat = 48
    private static let entryInset: CGFloat = 14
    private static let photosPerRow = 2
    private static let photoAspectRatio: CGFloat = 1.5
    private static let photoSpacing: CGFloat = 10
    private static let charcoal = UIColor(white: 0.18, alpha: 1)
    private static let muted = UIColor(white: 0.52, alpha: 1)

    static func timelineEntries(for vehicle: Vehicle) -> [TimelineEntry] {
        var entries: [TimelineEntry] = []
        var indices: [TimelineKey: Int] = [:]
        for record in vehicle.groupedServiceAndRepairTimeline.flatMap(\.entries) {
            let key = TimelineKey(date: Calendar.current.startOfDay(for: record.date), odometer: record.odometer)
            if let index = indices[key] {
                entries[index].items.append(record)
            } else {
                indices[key] = entries.count
                entries.append(TimelineEntry(date: key.date, odometer: key.odometer, items: [record]))
            }
        }
        return entries.sorted {
            $0.date == $1.date ? $0.odometer > $1.odometer : $0.date > $1.date
        }
    }

    static func appendixKey(for index: Int) -> String {
        var value = index + 1
        var result = ""
        let letters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        while value > 0 {
            value -= 1
            result.insert(letters[value % 26], at: result.startIndex)
            value /= 26
        }
        return result
    }

    static func export(vehicle: Vehicle, options: PDFExportOptions) -> URL? {
        let pageRect = CGRect(origin: .zero, size: options.paperSize.size)
        let records = timelineEntries(for: vehicle).flatMap(\.items)
        var appendices: [Appendix] = []
        let items = records.map { record in
            let attachments = options.includePDFDocuments ? documents(for: record).filter(\.isPDF) : []
            let appendix: Appendix? = attachments.isEmpty ? nil : Appendix(
                key: appendixKey(for: appendices.count), record: record, documents: attachments
            )
            if let appendix { appendices.append(appendix) }
            return (record: record, appendix: appendix)
        }

        let data = UIGraphicsPDFRenderer(bounds: pageRect).pdfData { context in
            let layout = ReportLayout(context: context, bounds: pageRect, vehicleName: vehicle.name)
            layout.beginPage()
            let exportDate = String(localized: "Exported \(Date.now.formatted(date: .abbreviated, time: .omitted))")
            let exportFont = UIFont.systemFont(ofSize: 12, weight: .semibold)
            let exportWidth = (exportDate as NSString).size(withAttributes: [.font: exportFont]).width
            draw(exportDate, at: CGPoint(x: pageRect.width - pageMargin - exportWidth, y: layout.y),
                 font: exportFont, color: muted)
            layout.text(String(localized: "Vehicle History"), font: .systemFont(ofSize: 12, weight: .semibold), color: muted)
            layout.y += 10
            layout.text(vehicle.name, font: .systemFont(ofSize: 20, weight: .semibold), color: .black)
            layout.text(
                String(localized: "Current Odometer: \(vehicle.odometer.formatted()) \(vehicle.distanceUnit.abbreviated)"),
                font: .systemFont(ofSize: 12), color: .black
            )

            layout.y += 30

            for item in items {
                let record = item.record
                let content = content(for: record)
                layout.record(
                    date: record.date, odometer: record.odometer, unit: vehicle.distanceUnit.abbreviated,
                    title: content.title, cost: options.includeCosts ? content.cost?.asCurrency() ?? "" : "",
                    note: options.includeNotes ? content.note : "",
                    appendix: item.appendix?.key,
                    images: options.includePhotos ? content.photos.compactMap { downsampledImage(from: $0.imageData) } : []
                )
            }
        }

        do {
            guard let report = PDFDocument(data: data) else { return nil }
            for appendix in appendices {
                let name = content(for: appendix.record).title
                let date = appendix.record.date.formatted(date: .long, time: .omitted)
                let distance = "\(appendix.record.odometer.formatted()) \(vehicle.distanceUnit.abbreviated)"
                let header = String(localized: "Appendix \(appendix.key): \(name) — \(date) (\(distance))")
                for attachment in appendix.documents {
                    guard let source = PDFDocument(data: attachment.documentData),
                          !source.isLocked, source.pageCount > 0 else {
                        throw CocoaError(.fileReadCorruptFile)
                    }
                    for index in 0..<source.pageCount {
                        guard let page = source.page(at: index) else { throw CocoaError(.fileReadCorruptFile) }
                        let stamped = try appendixPage(page, header: header)
                        report.insert(stamped, at: report.pageCount)
                    }
                }
            }
            let fileName = String(localized: "\(vehicle.name) Records") + ".pdf"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            guard let output = report.dataRepresentation() else { return nil }
            try output.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    private final class ReportLayout {
        let context: UIGraphicsPDFRendererContext
        let bounds: CGRect
        let vehicleName: String
        var y: CGFloat = pageMargin
        var pageNumber = 0
        var width: CGFloat { bounds.width - pageMargin * 2 }
        var bottom: CGFloat { bounds.height - pageMargin - 20 }
        var contentHeight: CGFloat { bottom - pageMargin }

        init(context: UIGraphicsPDFRendererContext, bounds: CGRect, vehicleName: String) {
            self.context = context
            self.bounds = bounds
            self.vehicleName = vehicleName
        }

        func beginPage() {
            context.beginPage()
            pageNumber += 1
            y = pageMargin
            let footer = String(localized: "\(vehicleName) • Page \(pageNumber)")
            let font = UIFont.systemFont(ofSize: 8)
            // Keep the footer to one line even for long vehicle names.
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineBreakMode = .byTruncatingTail
            (footer as NSString).draw(in: CGRect(x: pageMargin, y: bounds.height - 35, width: width, height: 12),
                                     withAttributes: [.font: font, .foregroundColor: muted, .paragraphStyle: paragraph])
        }

        func ensureSpace(_ height: CGFloat) {
            if y + height > bottom { beginPage() }
        }

        func text(_ value: String, font: UIFont, color: UIColor, inset: CGFloat = 0) {
            for line in lines(value, font: font, width: width - inset) {
                let height = ceil(font.lineHeight) + 3
                ensureSpace(height)
                draw(line, at: CGPoint(x: pageMargin + inset, y: y), font: font, color: color)
                y += height
            }
        }

        private var displayedYear: Int?
        private var yearPage = 0

        private struct Row {
            let height: CGFloat
            let draw: (CGFloat) -> Void
        }

        func record(date: Date, odometer: Int, unit: String, title: String, cost: String,
                    note: String, appendix: String?, images: [UIImage]) {
            let innerWidth = width - entryInset * 2
            let x = pageMargin + entryInset
            let titleFont = UIFont.systemFont(ofSize: 12, weight: .semibold)
            let noteFont = UIFont.systemFont(ofSize: 10.5)
            let costWidth = cost.isEmpty ? 0 : ceil((cost as NSString).size(withAttributes: [.font: titleFont]).width)
            var rows: [Row] = []
            for (index, line) in lines(title, font: titleFont, width: innerWidth - (cost.isEmpty ? 0 : costWidth + 18)).enumerated() {
                rows.append(Row(height: 18) { y in
                    PDFExporter.draw(line, at: CGPoint(x: x, y: y), font: titleFont, color: charcoal)
                    if index == 0 {
                        PDFExporter.draw(cost, at: CGPoint(x: x + innerWidth - costWidth, y: y), font: titleFont, color: charcoal)
                    }
                })
            }
            if !note.isEmpty {
                rows.append(Row(height: 6) { _ in })
                for line in lines(note, font: noteFont, width: innerWidth) {
                    rows.append(Row(height: 16) { y in
                        PDFExporter.draw(line, at: CGPoint(x: x, y: y), font: noteFont, color: muted)
                    })
                }
            }
            if let appendix {
                rows.append(Row(height: 7) { _ in })
                rows.append(Row(height: 15) { y in
                    // Rasterize the symbol to keep its appearance reliable in PDF output.
                    if let symbol = UIImage(systemName: "paperclip")?.withTintColor(muted, renderingMode: .alwaysOriginal) {
                        let size = CGSize(width: 11, height: 11)
                        let icon = UIGraphicsImageRenderer(size: size).image { _ in
                            symbol.draw(in: CGRect(origin: .zero, size: size))
                        }
                        icon.draw(in: CGRect(x: x, y: y, width: 11, height: 11))
                    }
                    PDFExporter.draw(String(localized: "See Appendix \(appendix) for attached documents"), at: CGPoint(x: x + 16, y: y),
                                     font: .systemFont(ofSize: 9), color: muted)
                })
            }
            let photoHeight = photoWidth(in: innerWidth) / photoAspectRatio
            for start in stride(from: 0, to: images.count, by: photosPerRow) {
                let photos = Array(images[start..<min(start + photosPerRow, images.count)])
                rows.append(Row(height: photoHeight + 10) { y in
                    drawPhotoRow(photos, in: CGRect(x: x, y: y + 10, width: innerWidth, height: photoHeight))
                })
            }

            let year = Calendar.current.component(.year, from: date)
            let metadata = "\(date.formatted(date: .long, time: .omitted)) · \(odometer.formatted()) \(unit)"
            let metadataFont = UIFont.systemFont(ofSize: 9)
            let metadataLines = lines(metadata, font: metadataFont, width: innerWidth)
            let topPadding = entryInset + CGFloat(metadataLines.count) * 13 + 7
            let overhead = topPadding + entryInset
            let totalHeight = overhead + rows.reduce(0) { $0 + $1.height }
            let yearTopSpacing: CGFloat = 15
            let yearFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
            let yearHeight = yearTopSpacing + ceil(yearFont.lineHeight) + 10
            let needsYear = displayedYear != year || yearPage != pageNumber
            // Move a whole record to the next page whenever it can fit there intact.
            let required = min(totalHeight, contentHeight - yearHeight)
            if y + required + (needsYear ? yearHeight : 0) > bottom { beginPage() }

            var offset = 0
            repeat {
                if displayedYear != year || yearPage != pageNumber {
                    draw(String(year), at: CGPoint(x: pageMargin + entryInset, y: y + yearTopSpacing),
                         font: yearFont, color: .accent)
                    y += yearHeight
                    displayedYear = year
                    yearPage = pageNumber
                }
                var end = offset
                var height = overhead
                while end < rows.count, y + height + rows[end].height <= bottom {
                    height += rows[end].height
                    end += 1
                }
                if end == offset && offset < rows.count {
                    beginPage()
                    continue
                }
                let card = UIBezierPath(roundedRect: CGRect(x: pageMargin, y: y, width: width, height: height), cornerRadius: 10)
                UIColor(white: 0.985, alpha: 1).setFill()
                card.fill()
                UIColor(white: 0.87, alpha: 1).setStroke()
                card.lineWidth = 0.5
                card.stroke()
                for (index, line) in metadataLines.enumerated() {
                    draw(line, at: CGPoint(x: x, y: y + entryInset + CGFloat(index) * 13), font: metadataFont, color: muted)
                }
                var rowY = y + topPadding
                for row in rows[offset..<end] {
                    row.draw(rowY)
                    rowY += row.height
                }
                y += height + 12
                offset = end
                if offset < rows.count { beginPage() }
            } while offset < rows.count
        }
    }

    // Core Text chooses word/cluster boundaries; each complete line is paginated independently.
    private static func lines(_ text: String, font: UIFont, width: CGFloat) -> [String] {
        guard !text.isEmpty else { return [] }
        let string = text as NSString
        let typesetter = CTTypesetterCreateWithAttributedString(NSAttributedString(string: text, attributes: [.font: font]))
        var offset = 0
        var result: [String] = []
        while offset < string.length {
            let count = max(1, CTTypesetterSuggestLineBreak(typesetter, offset, max(1, width)))
            result.append(string.substring(with: NSRange(location: offset, length: count)).trimmingCharacters(in: .newlines))
            offset += count
        }
        return result
    }

    private static func draw(_ text: String, at point: CGPoint, font: UIFont, color: UIColor) {
        (text as NSString).draw(at: point, withAttributes: [.font: font, .foregroundColor: color])
    }

    private static func rule(from start: CGPoint, to end: CGPoint) {
        muted.setStroke()
        let path = UIBezierPath()
        path.move(to: start)
        path.addLine(to: end)
        path.lineWidth = 0.35
        path.stroke()
    }

    private static func photoWidth(in rowWidth: CGFloat) -> CGFloat {
        (rowWidth - photoSpacing * CGFloat(photosPerRow - 1)) / CGFloat(photosPerRow)
    }

    private static func drawPhotoRow(_ images: [UIImage], in rect: CGRect) {
        let cellWidth = photoWidth(in: rect.width)
        for (index, image) in images.enumerated() {
            let cell = CGRect(x: rect.minX + CGFloat(index) * (cellWidth + photoSpacing), y: rect.minY, width: cellWidth, height: rect.height)
            let border = UIBezierPath(roundedRect: cell, cornerRadius: 8)
            UIColor.white.setFill()
            border.fill()
            // Match the footer's 3:2 thumbnail, but preserve the full portrait image.
            let widthScale = cell.width / image.size.width
            let heightScale = cell.height / image.size.height
            let scale = image.size.width >= image.size.height
                ? max(widthScale, heightScale)
                : min(widthScale, heightScale)
            let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let context = UIGraphicsGetCurrentContext()
            context?.saveGState()
            border.addClip()
            image.draw(in: CGRect(x: cell.midX - size.width / 2, y: cell.midY - size.height / 2, width: size.width, height: size.height))
            context?.restoreGState()
            UIColor(white: 0.78, alpha: 1).setStroke()
            border.lineWidth = 0.5
            border.stroke()
        }
    }

    private static func appendixPage(_ page: PDFPage, header: String) throws -> PDFPage {
        guard let pageRef = page.pageRef else { throw CocoaError(.fileReadCorruptFile) }
        let crop = page.bounds(for: .cropBox)
        let rotated = abs(page.rotation % 180) == 90
        let size = rotated ? CGSize(width: crop.height, height: crop.width) : crop.size
        guard size.width > 0, size.height > 0 else { throw CocoaError(.fileReadCorruptFile) }
        let font = UIFont.systemFont(ofSize: 8, weight: .medium)
        let inset = min(pageMargin, size.width * 0.1)
        let verticalInset: CGFloat = 20
        let headerLines = lines(header, font: font, width: size.width - inset * 2)
        let headerHeight = CGFloat(headerLines.count) * 11 + verticalInset * 2
        // Add a slim margin rather than covering original receipt text. Preserve vector PDF content.
        let bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height + headerHeight)
        let data = UIGraphicsPDFRenderer(bounds: bounds).pdfData { context in
            context.beginPage()
            let cg = context.cgContext
            cg.saveGState()
            cg.translateBy(x: 0, y: bounds.height)
            cg.scaleBy(x: 1, y: -1)
            cg.concatenate(pageRef.getDrawingTransform(.cropBox, rect: CGRect(origin: .zero, size: size), rotate: 0, preserveAspectRatio: true))
            cg.drawPDFPage(pageRef)
            // Annotation drawing uses coordinates relative to the crop-box origin.
            cg.translateBy(x: crop.minX, y: crop.minY)
            for annotation in page.annotations where annotation.shouldDisplay {
                annotation.draw(with: .cropBox, in: cg)
            }
            cg.restoreGState()
            for (index, line) in headerLines.enumerated() {
                draw(line, at: CGPoint(x: inset, y: verticalInset + CGFloat(index) * 11), font: font, color: charcoal)
            }
            rule(from: CGPoint(x: inset, y: headerHeight - 10), to: CGPoint(x: size.width - inset, y: headerHeight - 10))
        }
        guard let result = PDFDocument(data: data)?.page(at: 0) else { throw CocoaError(.fileReadCorruptFile) }
        return result
    }

    private static func documents(for record: VehicleExportRecord) -> [AttachedDocument] {
        switch record.type {
        case .serviceRecord(let record): record.sortedDocumentsArray
        case .serviceLog(let log): log.sortedDocumentsArray
        case .repair(let repair): repair.sortedDocumentsArray
        }
    }

    private static func content(for record: VehicleExportRecord) -> (title: String, note: String, cost: Double?, photos: [Photo]) {
        switch record.type {
        case .serviceRecord(let serviceRecord):
            return (
                serviceRecord.service?.name ?? String(localized: "Service", comment: "Fallback name for a service record"),
                serviceRecord.note.trimmingCharacters(in: .whitespacesAndNewlines),
                serviceRecord.cost,
                serviceRecord.sortedPhotosArray
            )
        case .serviceLog(let serviceLog):
            return (
                serviceLog.sortedServicesArray.map(\.name).formatted(.list(type: .and)),
                serviceLog.note.trimmingCharacters(in: .whitespacesAndNewlines),
                serviceLog.cost,
                serviceLog.sortedPhotosArray
            )
        case .repair(let repair):
            return (
                repair.name,
                repair.note.trimmingCharacters(in: .whitespacesAndNewlines),
                repair.cost,
                repair.sortedPhotosArray
            )
        }
    }

    private static func downsampledImage(from data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 1_600
              ] as CFDictionary) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

}
