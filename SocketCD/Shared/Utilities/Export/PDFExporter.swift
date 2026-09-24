//
//  PDFExporter.swift
//  SocketCD
//
//  Created by Justin Risner on 7/25/25.
//

import ImageIO
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
    var includePhotos = true
    var includeCosts = true
    var includeNotes = false
}

struct PDFExporter {
    private static let pageMargin: CGFloat = 48
    private static let footerHeight: CGFloat = 24
    private static let blockSpacing: CGFloat = 8
    private static let photoSpacing: CGFloat = 8
    private static let maximumPhotoHeight: CGFloat = 170
    private static let entryInset: CGFloat = 14
    private static let noteInset: CGFloat = 25
    private static let photoCornerRadius: CGFloat = 6
    private static let inkColor = UIColor(white: 0.12, alpha: 1)
    private static let secondaryInkColor = UIColor(white: 0.38, alpha: 1)
    private static let accentColor = UIColor(red: 0.20, green: 0.36, blue: 0.52, alpha: 1)

    private static let titleAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
        .foregroundColor: secondaryInkColor
    ]
    private static let vehicleAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 26, weight: .bold),
        .foregroundColor: inkColor
    ]
    private static let odometerAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 15, weight: .medium),
        .foregroundColor: secondaryInkColor
    ]
    private static let dateAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
        .foregroundColor: accentColor
    ]
    private static let recordTitleAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
        .foregroundColor: inkColor
    ]
    private static let metadataAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 10),
        .foregroundColor: secondaryInkColor
    ]
    private static let noteAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 10.5),
        .foregroundColor: secondaryInkColor
    ]

    static func export(vehicle: Vehicle, options: PDFExportOptions) -> URL? {
        let pageRect = CGRect(origin: .zero, size: options.paperSize.size)
        let fileName = String(
            localized: "\(vehicle.name) Records",
            comment: "Filename for an exported vehicle service-history document"
        ) + ".pdf"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let settings = AppSettingsStore.shared
        var cursorY: CGFloat = 0
        var pageNumber = 0

        do {
            try renderer.writePDF(to: fileURL) { context in
                func beginPage() {
                    context.beginPage()
                    UIColor.white.setFill()
                    UIRectFill(pageRect)
                    pageNumber += 1
                    cursorY = pageMargin
                    drawFooter(vehicleName: vehicle.name, pageNumber: pageNumber, pageRect: pageRect)
                }

                func ensureSpace(_ height: CGFloat) {
                    let contentBottom = pageRect.height - pageMargin - footerHeight
                    if cursorY + height > contentBottom {
                        beginPage()
                    }
                }

                beginPage()

                cursorY += drawTwoColumnLine(
                    left: String(localized: "Service & Repair History", comment: "PDF document title"),
                    right: String(
                        localized: "Exported \(Date.now.formatted(date: .abbreviated, time: .omitted))",
                        comment: "PDF export date"
                    ),
                    atY: cursorY,
                    pageRect: pageRect,
                    leftAttributes: titleAttributes,
                    rightAttributes: metadataAttributes
                ) + 12
                cursorY += drawText(
                    vehicle.name,
                    atY: cursorY,
                    pageRect: pageRect,
                    attributes: vehicleAttributes
                ) + 5
                cursorY += drawText(
                    String(
                        localized: "Current odometer: \(vehicle.odometer.formatted()) \(settings.distanceUnit.abbreviated)",
                        comment: "Current vehicle odometer shown in a PDF header"
                    ),
                    atY: cursorY,
                    pageRect: pageRect,
                    attributes: odometerAttributes
                ) + 24

                for group in vehicle.groupedServiceAndRepairTimeline {
                    ensureSpace(72)
                    let odometers = Set(group.entries.map(\.odometer))
                    let commonOdometer = odometers.count == 1 ? odometers.first : nil
                    let costs = group.entries.map { content(for: $0).cost }
                    let hasCommonCost = costs.dropFirst().allSatisfy { $0 == costs.first }
                    let commonCost = hasCommonCost ? costs.first ?? nil : nil
                    var groupMetadata: [String] = []
                    if let commonOdometer {
                        groupMetadata.append(String(
                            localized: "\(commonOdometer.formatted()) \(settings.distanceUnit.abbreviated)",
                            comment: "An odometer reading and its abbreviated distance unit"
                        ))
                    }
                    if options.includeCosts, let commonCost {
                        groupMetadata.append(commonCost.asCurrency())
                    }
                    cursorY += drawDateHeader(
                        group.date,
                        metadata: groupMetadata.joined(separator: "   •   "),
                        atY: cursorY,
                        pageRect: pageRect
                    ) + 12

                    for record in group.entries {
                        let content = content(for: record)
                        let titleHeight = measuredHeight(
                            content.title,
                            width: contentWidth(for: pageRect) - noteInset,
                            attributes: recordTitleAttributes
                        )
                        ensureSpace(titleHeight + 32)

                        let titleY = cursorY
                        var metadata: [String] = []
                        if commonOdometer == nil {
                            metadata.append(String(
                                localized: "\(record.odometer.formatted()) \(settings.distanceUnit.abbreviated)",
                                comment: "An odometer reading and its abbreviated distance unit"
                            ))
                        }
                        if options.includeCosts, !hasCommonCost, let cost = content.cost {
                            metadata.append(cost.asCurrency())
                        }
                        cursorY += drawTwoColumnLine(
                            left: content.title,
                            right: metadata.joined(separator: "   ·   "),
                            atY: cursorY,
                            pageRect: pageRect,
                            leftAttributes: recordTitleAttributes,
                            rightAttributes: metadataAttributes,
                            inset: noteInset
                        ) + 5
                        NSString(string: "•").draw(
                            at: CGPoint(x: pageMargin + entryInset, y: titleY),
                            withAttributes: recordTitleAttributes
                        )

                        if options.includeNotes, !content.note.isEmpty {
                            let note = String(
                                localized: "Note: \(content.note)",
                                comment: "Label followed by a user-entered service or repair note"
                            )
                            let noteHeight = measuredHeight(
                                note,
                                width: contentWidth(for: pageRect) - noteInset,
                                attributes: noteAttributes
                            )
                            ensureSpace(noteHeight)
                            cursorY += drawText(
                                note,
                                atY: cursorY,
                                pageRect: pageRect,
                                attributes: noteAttributes,
                                inset: noteInset
                            ) + blockSpacing
                        }

                        if options.includePhotos {
                            let images = content.photos.compactMap { downsampledImage(from: $0.imageData) }
                            for rowStart in stride(from: 0, to: images.count, by: 2) {
                                let row = Array(images[rowStart..<min(rowStart + 2, images.count)])
                                let rowHeight = photoRowHeight(images: row, pageRect: pageRect, inset: entryInset)
                                ensureSpace(rowHeight + photoSpacing)
                                drawPhotoRow(images: row, atY: cursorY, height: rowHeight, pageRect: pageRect, inset: entryInset)
                                cursorY += rowHeight + photoSpacing
                            }
                        }

                        cursorY += 10
                    }

                    cursorY += 16
                }
            }
            return fileURL
        } catch {
            return nil
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

    @discardableResult
    private static func drawText(
        _ text: String,
        atY y: CGFloat,
        pageRect: CGRect,
        attributes: [NSAttributedString.Key: Any],
        inset: CGFloat = 0
    ) -> CGFloat {
        let width = contentWidth(for: pageRect) - inset
        let height = measuredHeight(text, width: width, attributes: attributes)
        NSString(string: text).draw(
            with: CGRect(x: pageMargin + inset, y: y, width: width, height: height),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )
        return height
    }

    private static func measuredHeight(
        _ text: String,
        width: CGFloat,
        attributes: [NSAttributedString.Key: Any]
    ) -> CGFloat {
        ceil(NSString(string: text).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        ).height)
    }

    private static func drawTwoColumnLine(
        left: String,
        right: String,
        atY y: CGFloat,
        pageRect: CGRect,
        leftAttributes: [NSAttributedString.Key: Any],
        rightAttributes: [NSAttributedString.Key: Any],
        inset: CGFloat = 0
    ) -> CGFloat {
        let availableWidth = contentWidth(for: pageRect) - inset
        let rightWidth = right.isEmpty ? 0 : min(
            ceil(NSString(string: right).size(withAttributes: rightAttributes).width),
            availableWidth * 0.45
        )
        let gap: CGFloat = right.isEmpty ? 0 : 16
        let leftWidth = availableWidth - rightWidth - gap
        let leftHeight = measuredHeight(left, width: leftWidth, attributes: leftAttributes)
        let rightHeight = measuredHeight(right, width: rightWidth, attributes: rightAttributes)

        NSString(string: left).draw(
            with: CGRect(x: pageMargin + inset, y: y, width: leftWidth, height: leftHeight),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: leftAttributes,
            context: nil
        )
        if !right.isEmpty {
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .right
            var alignedAttributes = rightAttributes
            alignedAttributes[.paragraphStyle] = paragraph
            NSString(string: right).draw(
                with: CGRect(
                    x: pageRect.width - pageMargin - rightWidth,
                    y: y,
                    width: rightWidth,
                    height: rightHeight
                ),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: alignedAttributes,
                context: nil
            )
        }
        return max(leftHeight, rightHeight)
    }

    private static func drawPhotoRow(images: [UIImage], atY y: CGFloat, height: CGFloat, pageRect: CGRect, inset: CGFloat) {
        let cellWidth = (contentWidth(for: pageRect) - inset - photoSpacing) / 2
        for (index, image) in images.enumerated() {
            let cellRect = CGRect(
                x: pageMargin + inset + CGFloat(index) * (cellWidth + photoSpacing),
                y: y,
                width: cellWidth,
                height: height
            )
            let imageRect = aspectFitRect(for: image.size, in: cellRect)
            UIGraphicsGetCurrentContext()?.saveGState()
            UIBezierPath(roundedRect: imageRect, cornerRadius: photoCornerRadius).addClip()
            image.draw(in: imageRect)
            UIGraphicsGetCurrentContext()?.restoreGState()
        }
    }

    private static func photoRowHeight(images: [UIImage], pageRect: CGRect, inset: CGFloat) -> CGFloat {
        let cellWidth = (contentWidth(for: pageRect) - inset - photoSpacing) / 2
        return images.map { image in
            min(maximumPhotoHeight, cellWidth * image.size.height / max(image.size.width, 1))
        }.max() ?? 0
    }

    private static func aspectFitRect(for imageSize: CGSize, in bounds: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return bounds }
        let scale = min(bounds.width / imageSize.width, bounds.height / imageSize.height)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        return CGRect(
            x: bounds.midX - size.width / 2,
            y: bounds.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
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

    private static func drawDateHeader(_ date: Date, metadata: String, atY y: CGFloat, pageRect: CGRect) -> CGFloat {
        let lineHeight = drawTwoColumnLine(
            left: date.formatted(date: .long, time: .omitted),
            right: metadata,
            atY: y,
            pageRect: pageRect,
            leftAttributes: dateAttributes,
            rightAttributes: metadataAttributes
        )
        let ruleY = y + lineHeight + 7
        UIColor(white: 0.84, alpha: 1).setStroke()
        let rule = UIBezierPath()
        rule.move(to: CGPoint(x: pageMargin, y: ruleY))
        rule.addLine(to: CGPoint(x: pageRect.width - pageMargin, y: ruleY))
        rule.lineWidth = 0.5
        rule.stroke()
        return lineHeight + 7
    }

    private static func drawFooter(vehicleName: String, pageNumber: Int, pageRect: CGRect) {
        let text = String(
            localized: "\(vehicleName) • Page \(pageNumber)",
            comment: "PDF footer containing a vehicle name and page number"
        )
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8),
            .foregroundColor: UIColor(white: 0.5, alpha: 1)
        ]
        NSString(string: text).draw(
            at: CGPoint(x: pageMargin, y: pageRect.height - pageMargin + 10),
            withAttributes: footerAttributes
        )
    }

    private static func contentWidth(for pageRect: CGRect) -> CGFloat {
        pageRect.width - pageMargin * 2
    }
}
