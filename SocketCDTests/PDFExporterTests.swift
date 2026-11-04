//
//  PDFExporterTests.swift
//  SocketCDTests
//

import CoreData
import PDFKit
import Testing
import UIKit
import UniformTypeIdentifiers
@testable import SocketCD

@Suite("PDF Exporter Tests", .serialized)
struct PDFExporterTests {
    @Test func `Exports the selected paper size`() throws {
        let controller = TestDataController()
        let vehicle = makeVehicle(in: controller.context)

        for paperSize in PDFPaperSize.allCases {
            let url = try #require(PDFExporter.export(
                vehicle: vehicle,
                options: PDFExportOptions(paperSize: paperSize, includePhotos: false)
            ))
            let document = try #require(PDFDocument(url: url))
            let page = try #require(document.page(at: 0))

            #expect(abs(page.bounds(for: .mediaBox).width - paperSize.size.width) < 1)
            #expect(abs(page.bounds(for: .mediaBox).height - paperSize.size.height) < 1)
        }
    }

    @Test func `Including photos adds photo pages when needed`() throws {
        let controller = TestDataController()
        let vehicle = makeVehicle(in: controller.context)
        let repair = makeRepair(for: vehicle, in: controller.context)
        let imageData = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 600))
            .jpegData(withCompressionQuality: 0.8) { context in
                UIColor.systemBlue.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 300, height: 600))
            }

        repair.photos = NSSet(array: (0..<24).map { index in
            let photo = Photo(context: controller.context)
            photo.id = UUID()
            photo.timeStamp = Date(timeIntervalSince1970: TimeInterval(index))
            photo.imageData = imageData
            return photo
        })

        let withoutPhotosURL = try #require(PDFExporter.export(
            vehicle: vehicle,
            options: PDFExportOptions(paperSize: .usLetter, includePhotos: false)
        ))
        let withoutPhotosData = try Data(contentsOf: withoutPhotosURL)
        let withPhotosURL = try #require(PDFExporter.export(
            vehicle: vehicle,
            options: PDFExportOptions(paperSize: .usLetter, includePhotos: true)
        ))
        let withPhotosData = try Data(contentsOf: withPhotosURL)
        let withoutPhotos = try #require(PDFDocument(data: withoutPhotosData))
        let withPhotos = try #require(PDFDocument(data: withPhotosData))

        #expect(withPhotos.pageCount > withoutPhotos.pageCount)
    }

    @Test func `Corrupt photos do not prevent export`() throws {
        let controller = TestDataController()
        let vehicle = makeVehicle(in: controller.context)
        let repair = makeRepair(for: vehicle, in: controller.context)
        let photo = Photo(context: controller.context)
        photo.id = UUID()
        photo.timeStamp = .now
        photo.imageData = Data("not an image".utf8)
        repair.photos = NSSet(object: photo)

        let url = try #require(PDFExporter.export(
            vehicle: vehicle,
            options: PDFExportOptions(paperSize: .a4, includePhotos: true)
        ))

        #expect(PDFDocument(url: url)?.pageCount == 1)
    }

    @Test func `Records with matching date and odometer retain their own metadata`() throws {
        let controller = TestDataController()
        let vehicle = makeVehicle(in: controller.context)
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let firstRepair = makeRepair(for: vehicle, in: controller.context)
        firstRepair.date = date
        let secondRepair = makeRepair(for: vehicle, in: controller.context)
        secondRepair.name = "Tire rotation"
        secondRepair.date = date

        let url = try #require(PDFExporter.export(
            vehicle: vehicle,
            options: PDFExportOptions(paperSize: .usLetter, includePhotos: false)
        ))
        let text = try #require(PDFDocument(url: url)?.string)
        let dateHeading = date.formatted(date: .long, time: .omitted)

        #expect(text.components(separatedBy: dateHeading).count - 1 == 2)
        #expect(text.contains("Brake repair"))
        #expect(text.contains("Tire rotation"))
        #expect(text.components(separatedBy: "41,500").count - 1 == 2)
        #expect(text.components(separatedBy: 325.0.asCurrency()).count - 1 == 2)
    }

    @Test func `Different odometers and costs stay with their entries`() throws {
        let controller = TestDataController()
        let vehicle = makeVehicle(in: controller.context)
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let firstRepair = makeRepair(for: vehicle, in: controller.context)
        firstRepair.date = date
        let secondRepair = makeRepair(for: vehicle, in: controller.context)
        secondRepair.name = "Tire rotation"
        secondRepair.date = date
        secondRepair.odometer = 41_750
        secondRepair.cost = 90

        let url = try #require(PDFExporter.export(
            vehicle: vehicle,
            options: PDFExportOptions(paperSize: .usLetter, includePhotos: false)
        ))
        let text = try #require(PDFDocument(url: url)?.string)

        #expect(text.contains("41,500"))
        #expect(text.contains("41,750"))
        #expect(PDFExporter.timelineEntries(for: vehicle).count == 2)
        #expect(text.contains(325.0.asCurrency()))
        #expect(text.contains(90.0.asCurrency()))
    }

    @Test func `Costs can be excluded`() throws {
        let controller = TestDataController()
        let vehicle = makeVehicle(in: controller.context)
        _ = makeRepair(for: vehicle, in: controller.context)

        let withCostsURL = try #require(PDFExporter.export(
            vehicle: vehicle,
            options: PDFExportOptions(paperSize: .usLetter, includePhotos: false, includeCosts: true)
        ))
        let withCostsData = try Data(contentsOf: withCostsURL)
        let withoutCostsURL = try #require(PDFExporter.export(
            vehicle: vehicle,
            options: PDFExportOptions(paperSize: .usLetter, includePhotos: false, includeCosts: false)
        ))
        let withoutCostsData = try Data(contentsOf: withoutCostsURL)
        let withCostsText = try #require(PDFDocument(data: withCostsData)?.string)
        let withoutCostsText = try #require(PDFDocument(data: withoutCostsData)?.string)

        #expect(withCostsText.contains(325.0.asCurrency()))
        #expect(!withoutCostsText.contains(325.0.asCurrency()))
    }

    @Test func `Notes can be excluded or included`() throws {
        let controller = TestDataController()
        let vehicle = makeVehicle(in: controller.context)
        let repair = makeRepair(for: vehicle, in: controller.context)

        let withoutNotesURL = try #require(PDFExporter.export(
            vehicle: vehicle,
            options: PDFExportOptions(paperSize: .usLetter, includePhotos: false, includeNotes: false)
        ))
        let withoutNotesData = try Data(contentsOf: withoutNotesURL)
        let withNotesURL = try #require(PDFExporter.export(
            vehicle: vehicle,
            options: PDFExportOptions(
                paperSize: .usLetter,
                includePhotos: false,
                includeCosts: true,
                includeNotes: true
            )
        ))
        let withNotesData = try Data(contentsOf: withNotesURL)
        let withoutNotesText = try #require(PDFDocument(data: withoutNotesData)?.string)
        let withNotesText = try #require(PDFDocument(data: withNotesData)?.string)

        #expect(!withoutNotesText.contains(repair.note))
        #expect(withNotesText.contains(repair.note))
    }

    @Test func attachedPDFsFollowReportAndGroupMaintenanceServices() throws {
        let controller = TestDataController()
        let vehicle = makeVehicle(in: controller.context)
        let log = ServiceLog(context: controller.context)
        log.id = UUID()
        log.date = Date(timeIntervalSince1970: 1_700_000_000)
        for name in ["Oil change", "Tire rotation"] {
            let service = Service(context: controller.context)
            service.name = name
            service.vehicle = vehicle
            let record = ServiceRecord(context: controller.context)
            record.id = UUID()
            record.service = service
            record.serviceLog = log
        }
        let attachment = AttachedDocument(context: controller.context)
        attachment.fileName = "Invoice.pdf"
        attachment.contentType = .pdf
        let bounds = CGRect(x: 0, y: 0, width: 400, height: 300)
        attachment.documentData = UIGraphicsPDFRenderer(bounds: bounds).pdfData { context in
            for text in ["Invoice first page", "Invoice second page"] {
                context.beginPage()
                (text as NSString).draw(at: CGPoint(x: 20, y: 20), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 12)
                ])
            }
        }
        log.documents = NSSet(object: attachment)
        let repair = makeRepair(for: vehicle, in: controller.context)
        repair.date = log.date.addingTimeInterval(-86_400)
        let repairAttachment = AttachedDocument(context: controller.context)
        repairAttachment.fileName = "Repair.pdf"
        repairAttachment.contentType = .pdf
        repairAttachment.documentData = attachment.documentData
        repair.documents = NSSet(object: repairAttachment)

        let plainURL = try #require(PDFExporter.export(vehicle: vehicle, options: PDFExportOptions()))
        let plain = try #require(PDFDocument(data: Data(contentsOf: plainURL)))
        let url = try #require(PDFExporter.export(
            vehicle: vehicle, options: PDFExportOptions(includePDFDocuments: true)
        ))
        let result = try #require(PDFDocument(url: url))
        #expect(result.pageCount == plain.pageCount + 4)
        let timeline = try #require(result.page(at: 0)?.string)
        #expect(timeline.contains("See Appendix A"))
        #expect(timeline.contains("See Appendix B"))
        #expect(!(plain.string ?? "").contains("See Appendix"))
        for index in 0..<4 {
            let page = try #require(result.page(at: plain.pageCount + index))
            let text = try #require(page.string)
            #expect(text.contains(index < 2 ? "Appendix A:" : "Appendix B:"))
            #expect(text.contains(index % 2 == 0 ? "Invoice first page" : "Invoice second page"))
            #expect(page.bounds(for: .mediaBox).width == bounds.width)
            #expect(page.bounds(for: .mediaBox).height > bounds.height)
            if index < 2 {
                #expect(text.contains("Oil change"))
                #expect(text.contains("Tire rotation"))
            } else {
                #expect(text.contains("Brake repair"))
            }
        }
    }

    @Test func invalidPDFDoesNotSilentlyProduceIncompleteExport() {
        let controller = TestDataController()
        let vehicle = makeVehicle(in: controller.context)
        let repair = makeRepair(for: vehicle, in: controller.context)
        let attachment = AttachedDocument(context: controller.context)
        attachment.contentType = .pdf
        attachment.documentData = Data("invalid PDF".utf8)
        repair.documents = NSSet(object: attachment)
        #expect(PDFExporter.export(vehicle: vehicle, options: PDFExportOptions()) != nil)
        #expect(PDFExporter.export(
            vehicle: vehicle, options: PDFExportOptions(includePDFDocuments: true)
        ) == nil)
    }

    @Test func appendixLettersContinueAfterZ() {
        #expect(PDFExporter.appendixKey(for: 0) == "A")
        #expect(PDFExporter.appendixKey(for: 25) == "Z")
        #expect(PDFExporter.appendixKey(for: 26) == "AA")
        #expect(PDFExporter.appendixKey(for: 51) == "AZ")
        #expect(PDFExporter.appendixKey(for: 52) == "BA")
    }

    @Test func longNotesFlowAcrossPagesWithoutLosingText() throws {
        let controller = TestDataController()
        let vehicle = makeVehicle(in: controller.context)
        let repair = makeRepair(for: vehicle, in: controller.context)
        repair.note = (0..<300).map { "Inspection item \($0): Checked components and verified operation." }.joined(separator: "\n")
        let url = try #require(PDFExporter.export(vehicle: vehicle, options: PDFExportOptions()))
        let document = try #require(PDFDocument(url: url))
        let text = try #require(document.string)
        #expect(document.pageCount > 1)
        #expect(text.contains("Inspection item 0:"))
        #expect(text.contains("Inspection item 299:"))
        for index in 0..<document.pageCount {
            let page = try #require(document.page(at: index))
            let selection = try #require(page.selection(for: page.bounds(for: .mediaBox)))
            #expect(selection.bounds(for: page).minY >= 20)
        }
    }

    private func makeVehicle(in context: NSManagedObjectContext) -> Vehicle {
        let vehicle = Vehicle(context: context)
        vehicle.id = UUID()
        vehicle.name = "PDF Test \(UUID().uuidString)"
        vehicle.odometer = 42_000
        return vehicle
    }

    private func makeRepair(for vehicle: Vehicle, in context: NSManagedObjectContext) -> Repair {
        let repair = Repair(context: context)
        repair.id = UUID()
        repair.vehicle = vehicle
        repair.name = "Brake repair"
        repair.date = .now
        repair.odometer = 41_500
        repair.note = "Replaced front pads and inspected rotors."
        repair.cost = 325
        return repair
    }
}
