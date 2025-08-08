//
//  CSVExporter.swift
//  SocketCD
//
//  Created by Justin Risner on 8/8/25.
//

import SwiftUI

struct CSVExporter {
    // MARK: - Export only service and repair records
    static func exportServicesAndRepairs(for vehicle: Vehicle) -> URL? {
        let fileName = "\(vehicle.name) Service & Repairs.csv"
        let tempDirectory = NSTemporaryDirectory()
        let fileURL = URL(fileURLWithPath: tempDirectory, isDirectory: true).appendingPathComponent(fileName)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"

        var csvRows: [String] = []
        csvRows.append("Type,Date,Odometer,Name,Cost,Note")

        for entry in vehicle.serviceAndRepairTimeline {
            let date = dateFormatter.string(from: entry.date)
            let odometer = entry.odometer
            
            let cost: String
            switch entry.type {
            case .service(let record):
                cost = String(format: "%.2f", record.cost ?? 0)
            case .repair(let repair):
                cost = String(format: "%.2f", repair.cost ?? 0)
            }

            let name: String
            let note: String
            let type: String

            switch entry.type {
            case .service(let record):
                name = record.service?.name ?? "Service"
                note = record.note
                type = "Service"
            case .repair(let repair):
                name = repair.name
                note = repair.note
                type = "Repair"
            }

            // Escape quotes and commas in the note
            let escapedNote = "\"\(note.replacingOccurrences(of: "\"", with: "\"\""))\""
            let escapedName = "\"\(name.replacingOccurrences(of: "\"", with: "\"\""))\""

            let row = "\(type),\(date),\(odometer),\(escapedName),\(cost),\(escapedNote)"
            csvRows.append(row)
        }

        let csvString = csvRows.joined(separator: "\n")

        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to write CSV: \(error)")
            return nil
        }
    }
    
    // MARK: - Export only fill-up records
    static func exportFillups(for vehicle: Vehicle) -> URL? {
        let settings = AppSettings()
        
        let filename = "\(vehicle.name) Fill-ups.csv"
        let tempDirectory = NSTemporaryDirectory()
        let fileURL = URL(fileURLWithPath: tempDirectory, isDirectory: true).appendingPathComponent(filename)

        var allFillups: [String] = []

        let header = """
        Date,Odometer,\(settings.fuelEconomyUnit.volumeUnit)s of Fuel,Price per \(settings.fuelEconomyUnit.volumeUnit),Trip (\(settings.distanceUnit.abbreviated)),Fuel Economy (\(settings.fuelEconomyUnit.rawValue)),Total Cost,Full Tank?,Note
        """
        allFillups.append(header)

        // Helper to escape quotes
        func escape(_ string: String) -> String {
            "\"\(string.replacingOccurrences(of: "\"", with: "\"\""))\""
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none

        for fillup in vehicle.sortedFillupsArray {
            let dateString = dateFormatter.string(from: fillup.date)
            let odometerString = String(fillup.odometer)
            let volumeString = String(format: "%.2f", fillup.volume) // 2 decimals for volume
            let priceString = String(format: "%.2f", fillup.pricePerUnit ?? 0) // 2 decimals for price
            let tripString = String(fillup.tripDistance)
            let fuelEconomyString = String(format: "%.1f", fillup.fuelEconomy(settings: settings))
            let totalCostString = String(format: "%.2f", fillup.totalCost ?? 0)
            let fullTankString = fillup.fillType == .partialFill ? "No" : "Yes"
            let noteString = escape(fillup.note)

            let csvRow = [
                dateString,
                odometerString,
                volumeString,
                priceString,
                tripString,
                fuelEconomyString,
                totalCostString,
                fullTankString,
                noteString
            ].joined(separator: ",")

            allFillups.append(csvRow)
        }

        let csvString = allFillups.joined(separator: "\n")

        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to create fill-ups CSV: \(error)")
            return nil
        }
    }

    // MARK: - Export all records in one CSV file
    static func exportAllRecords(for vehicle: Vehicle) -> URL? {
        let settings = AppSettings()
        
        let fileName = "\(vehicle.name) All Records.csv"
        let tempDirectory = NSTemporaryDirectory()
        let fileURL = URL(fileURLWithPath: tempDirectory, isDirectory: true).appendingPathComponent(fileName)

        var rows: [String] = []

        let header = [
            "Type",
            "Date",
            "Odometer",
            "Name",
            "Cost",
            "Trip",
            "Fuel Economy",
            "Full Tank?",
            "Note"
        ].joined(separator: ",")

        rows.append(header)

        func escape(_ string: String) -> String {
            return "\"\(string.replacingOccurrences(of: "\"", with: "\"\""))\""
        }

        struct ExportRow {
            let type: String
            let date: Date
            let odometer: Int
            let name: String?
            let cost: Double?
            let trip: Int?
            let fuelEconomy: Double?
            let fullTank: Bool?
            let note: String
        }

        var combinedRows: [ExportRow] = []

        for record in vehicle.serviceAndRepairTimeline {
            switch record.type {
            case .service(let serviceRecord):
                combinedRows.append(
                    ExportRow(
                        type: "Service",
                        date: serviceRecord.date,
                        odometer: serviceRecord.odometer,
                        name: serviceRecord.service?.name,
                        cost: serviceRecord.cost ?? 0,
                        trip: nil,
                        fuelEconomy: nil,
                        fullTank: nil,
                        note: serviceRecord.note
                    )
                )
            case .repair(let repair):
                combinedRows.append(
                    ExportRow(
                        type: "Repair",
                        date: repair.date,
                        odometer: repair.odometer,
                        name: repair.name,
                        cost: repair.cost ?? 0,
                        trip: nil,
                        fuelEconomy: nil,
                        fullTank: nil,
                        note: repair.note
                    )
                )
            }
        }

        for fillup in vehicle.sortedFillupsArray {
            combinedRows.append(
                ExportRow(
                    type: "Fill-up",
                    date: fillup.date,
                    odometer: fillup.odometer,
                    name: nil,
                    cost: fillup.totalCost ?? 0,
                    trip: fillup.tripDistance,
                    fuelEconomy: fillup.fuelEconomy(settings: settings),
                    fullTank: fillup.fillType == .partialFill ? false : true,
                    note: fillup.note
                )
            )
        }

        combinedRows.sort { $0.date > $1.date }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none

        for row in combinedRows {
            let dateString = dateFormatter.string(from: row.date)
            let odometerString = String(row.odometer)
            let costString = row.cost != nil ? String(format: "%.2f", row.cost!) : ""
            let tripString = row.trip != nil ? String(row.trip!) : ""
            let fuelEconomyString = row.fuelEconomy != nil ? String(format: "%.1f", row.fuelEconomy!) : ""
            let fullTankString = row.fullTank.map { $0 ? "Yes" : "No" } ?? ""
            let nameString = row.name.map(escape) ?? ""
            let noteString = escape(row.note)

            let csvRow = [
                row.type,
                dateString,
                odometerString,
                nameString,
                costString,
                tripString,
                fuelEconomyString,
                fullTankString,
                noteString
            ].joined(separator: ",")

            rows.append(csvRow)
        }

        let csvString = rows.joined(separator: "\n")

        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to write combined CSV: \(error)")
            return nil
        }
    }
}
