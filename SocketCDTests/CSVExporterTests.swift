import CoreData
import Foundation
import Testing
@testable import SocketCD

@Suite("CSV Exporter Tests")
struct CSVExporterTests {
    @Test func formatsUnitCostsAndServiceNames() {
        let locale = Locale(identifier: "en_US")
        #expect(CSVExporter.unitCost(3.459, locale: locale) == "$3.459")
        #expect(CSVExporter.unitCost(3.45, locale: locale) == "$3.45")
        #expect(CSVExporter.unitCost(3, locale: locale) == "$3.00")
        #expect(CSVExporter.unitCost(3.456789, locale: locale) == "$3.46")
        #expect(CSVExporter.unitCost(nil, locale: locale) == "")
        #expect(CSVExporter.unitCost(3.45900000001, locale: locale) == "$3.46")
        #expect(CSVExporter.unitCost(40 / 12.345, locale: locale) == "$3.24")
        #expect(CSVExporter.unitCost(3.451, locale: locale) == "$3.451")
        #expect(CSVExporter.fuelVolume(12.345000000000002) == "12.345")
        #expect(CSVExporter.fuelVolume(12.300000000000002) == "12.3")
        #expect(CSVExporter.fuelVolume(12.34) == "12.34")
        #expect(CSVExporter.fuelVolume(12) == "12")
        #expect(CSVExporter.fuelVolume(12.3456789) == "12.346")
        #expect(CSVExporter.serviceNames(["Oil Change", "Timing Belt"]) == "Oil Change, Timing Belt")
    }

    @Test func selectionsFilterDocuments() throws {
        let controller = TestDataController()
        let vehicle = Vehicle(context: controller.context)
        for maintenance in [false, true] {
            for repairs in [false, true] {
                for fuel in [false, true] {
                    let options = CSVExportOptions(includeMaintenance: maintenance, includeRepairs: repairs, includeFillups: fuel)
                    #expect(options.hasSelection == (maintenance || repairs || fuel))
                    if !options.hasSelection {
                        #expect(throws: CSVExportError.self) {
                            try CSVExporter.documents(vehicle: vehicle, options: options)
                        }
                        continue
                    }
                    let documents = try CSVExporter.documents(vehicle: vehicle, options: options)
                    #expect(documents.contains { $0.filename == "Maintenance.csv" } == maintenance)
                    #expect(documents.contains { $0.filename == "Repairs.csv" } == repairs)
                    #expect(documents.contains { $0.filename == "Fill-ups.csv" } == fuel)
                    // Selected empty categories still have a useful header-only CSV.
                    #expect(documents.allSatisfy { parse($0.contents).count == 1 })
                    let url = try CSVExporter.export(vehicle: vehicle, options: options)
                    defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
                    if documents.count == 1, let document = documents.first {
                        #expect(url.lastPathComponent == document.filename)
                        #expect(try String(contentsOf: url, encoding: .utf8) == document.contents)
                    } else {
                        #expect(url.pathExtension == "zip")
                        #expect(Array(try Data(contentsOf: url).prefix(4)) == [0x50, 0x4b, 0x03, 0x04])
                    }
                }
            }
        }
    }

    @Test func createsZIPArchive() throws {
        let controller = TestDataController()
        let vehicle = Vehicle(context: controller.context)
        vehicle.name = "Car/Truck"
        let repair = Repair(context: controller.context)
        repair.vehicle = vehicle
        repair.name = "Archive verification"
        let url = try CSVExporter.export(vehicle: vehicle, options: CSVExportOptions())
        let data = try Data(contentsOf: url)
        #expect(url.lastPathComponent == "Car-Truck Records.zip")
        #expect(Array(data.prefix(4)) == [0x50, 0x4b, 0x03, 0x04])
        #expect(!FileManager.default.fileExists(atPath: url.deletingLastPathComponent().appendingPathComponent("Records").path))
        // Leave this temporary export for independent ZIP-reader verification.
        print("CSV_ARCHIVE_TEST_PATH=\(url.path)")
    }

    @Test func selectedColumnsPreserveEveryFormValue() throws {
        let controller = TestDataController()
        let vehicle = Vehicle(context: controller.context)
        vehicle.distanceUnit = .miles
        vehicle.volumeUnit = .usGallons
        let date = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 12)))
        let category = RepairCategory(context: controller.context)
        category.name = "Brakes, suspension"
        let repair = Repair(context: controller.context)
        repair.vehicle = vehicle
        repair.date = date
        repair.name = "Replace \"front\" pads"
        repair.category = category
        repair.odometer = 12345
        repair.cost = 123.456
        repair.note = "First line\nSecond line"

        let log = ServiceLog(context: controller.context)
        log.date = date
        log.cost = 45.678
        log.note = "Grouped service"
        let names = ["Oil, filter", "Tires \"rotation\""]
        for name in names {
            let service = Service(context: controller.context)
            service.name = name
            service.vehicle = vehicle
            let record = ServiceRecord(context: controller.context)
            record.service = service
            record.serviceLog = log
        }
        log.odometer = 12340

        let legacyService = Service(context: controller.context)
        legacyService.name = "Legacy service"
        legacyService.vehicle = vehicle
        let legacy = ServiceRecord(context: controller.context)
        legacy.service = legacyService
        legacy.date = date
        legacy.odometer = 12300
        legacy.cost = 12.345
        legacy.note = "Legacy note"

        let fillup = Fillup(context: controller.context)
        fillup.vehicle = vehicle
        fillup.date = date
        fillup.odometer = 12400
        fillup.volume = 12.345
        fillup.pricePerUnit = 3.459
        fillup.note = "Fuel, receipt\n\"Premium\""


        for fillType in FillType.allCases {
            fillup.fillType = fillType
            let documents = try CSVExporter.documents(vehicle: vehicle, options: CSVExportOptions())
            for document in documents {
                let table = parse(document.contents)
                let header = try #require(table.first)
                #expect(table.allSatisfy { $0.count == header.count })
                #expect(!header.contains { $0.contains("ID") || $0.contains("JSON") || $0 == "Type" })
                let rows = table.dropFirst().map { Dictionary(uniqueKeysWithValues: zip(header, $0)) }
                switch document.filename {
                case "Repairs.csv":
                    #expect(rows.count == 1)
                    #expect(!header.contains { $0.hasPrefix("Service") || $0.hasPrefix("Fuel") })
                    let row = try #require(rows.first)
                    #expect(row["Name"] == repair.name)
                    #expect(header == ["Date", "Odometer (mi)", "Name", "Total Cost", "Category", "Note"])
                    #expect(row["Category"] == category.name)
                    #expect(row["Date"] == "2026-10-12")
                    #expect(row["Odometer (mi)"] == 12345.formatted())
                    #expect(row["Total Cost"] == 123.456.asCurrency())
                    #expect(row["Note"] == repair.note)
                case "Maintenance.csv":
                    #expect(header == ["Date", "Services Performed", "Odometer (mi)", "Total Cost", "Note"])
                    #expect(rows.count == 2)
                    #expect(!header.contains("Name"))
                    #expect(!header.contains("Category"))
                    #expect(!header.contains { $0.hasPrefix("Fuel") })
                    let row = try #require(rows.first { $0["Note"] == log.note })
                    #expect(row["Services Performed"] == "\"Oil, filter\", \"Tires \"\"rotation\"\"\"")
                    #expect(row["Total Cost"] == 45.678.asCurrency())
                    #expect(row["Odometer (mi)"] == 12340.formatted())
                    let old = try #require(rows.first { $0["Note"] == legacy.note })
                    #expect(old["Services Performed"] == legacyService.name)
                    #expect(old["Total Cost"] == 12.345.asCurrency())
                case "Fill-ups.csv":
                    #expect(rows.count == 1)
                    #expect(!header.contains("Name"))
                    #expect(!header.contains("Category"))
                    #expect(!header.contains { $0.hasPrefix("Service") })
                    let row = try #require(rows.first)
                    #expect(Array(header.prefix(6)) == ["Date", "Odometer (mi)", "Fuel (US gal)", "Cost per US gal", "Total Cost", "Fill Type"])
                    #expect(row["Cost per US gal"] == 3.459.asCurrency(preservePrecision: true))
                    #expect(row["Fuel (US gal)"].flatMap(Double.init) == fillup.volume)
                    #expect(row["Total Cost"] == (12.345 * 3.459).asCurrency())
                    #expect(row["Fill Type"] == fillType.rawValue)
                    #expect(row["Note"] == fillup.note)
                    #expect(row["Odometer (mi)"] == 12400.formatted())
                default:
                    Issue.record("Unexpected CSV file")
                }
            }
        }
    }

    // Independent CSV reader for checking field alignment and escaped text.
    private func parse(_ csv: String) -> [[String]] {
        let characters = Array(csv)
        var table: [[String]] = []
        var row: [String] = []
        var field = ""
        var quoted = false
        var index = 0
        while index < characters.count {
            let character = characters[index]
            if character == "\"" {
                if quoted && index + 1 < characters.count && characters[index + 1] == "\"" {
                    field.append("\"")
                    index += 1
                } else {
                    quoted.toggle()
                }
            } else if character == "," && !quoted {
                row.append(field)
                field = ""
            } else if (character == "\r\n" || character == "\n" || character == "\r") && !quoted {
                row.append(field)
                table.append(row)
                row = []
                field = ""
            } else {
                field.append(character)
            }
            index += 1
        }
        return table
    }
}
