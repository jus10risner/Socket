import Foundation

struct CSVExportOptions {
    var includeMaintenance = true
    var includeRepairs = true
    var includeFillups = true

    var selectedKinds: [CSVRecordKind] {
        var kinds: [CSVRecordKind] = []
        if includeMaintenance { kinds.append(.maintenance) }
        if includeRepairs { kinds.append(.repairs) }
        if includeFillups { kinds.append(.fillups) }
        return kinds
    }

    var hasSelection: Bool {
        !selectedKinds.isEmpty
    }
}

enum CSVExportError: Error {
    case noRecordsSelected
    case archiveCreationFailed
}

enum CSVRecordKind: String, CaseIterable {
    case maintenance = "Maintenance"
    case repairs = "Repairs"
    case fillups = "Fill-ups"

    var filename: String { "\(rawValue).csv" }
}

struct CSVExportDocument {
    let filename: String
    let contents: String
}

/// Each selected record type gets an ordinary CSV. Multiple files are bundled in a ZIP.
struct CSVExporter {
    static func documents(vehicle: Vehicle, options: CSVExportOptions) throws -> [CSVExportDocument] {
        let kinds = options.selectedKinds
        guard !kinds.isEmpty else { throw CSVExportError.noRecordsSelected }
        return kinds.map {
            CSVExportDocument(filename: $0.filename, contents: csv(vehicle: vehicle, kind: $0))
        }
    }

    static func export(vehicle: Vehicle, options: CSVExportOptions) throws -> URL {
        let documents = try documents(vehicle: vehicle, options: options)
        let manager = FileManager.default
        let directory = manager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let name = vehicle.name.components(separatedBy: CharacterSet(charactersIn: "/:\\").union(.controlCharacters))
            .joined(separator: "-")
        let exportName = "\(name.isEmpty ? "Vehicle" : name) Records"
        let source = directory.appendingPathComponent(exportName, isDirectory: true)
        try manager.createDirectory(at: source, withIntermediateDirectories: true)
        var completed = false
        defer {
            try? manager.removeItem(at: source)
            if !completed { try? manager.removeItem(at: directory) }
        }
        if documents.count == 1, let document = documents.first {
            let url = directory.appendingPathComponent(document.filename)
            try document.contents.write(to: url, atomically: true, encoding: .utf8)
            completed = true
            return url
        }
        for document in documents {
            try document.contents.write(to: source.appendingPathComponent(document.filename),
                                        atomically: true, encoding: .utf8)
        }
        let url = directory.appendingPathComponent("\(exportName).zip")
        var coordinationError: NSError?
        var copyResult: Result<Void, Error> = .failure(CSVExportError.archiveCreationFailed)
        // Foundation creates a standard ZIP snapshot of a directory. Copy it inside
        // the accessor because the snapshot is removed when coordination finishes.
        NSFileCoordinator().coordinate(readingItemAt: source, options: .forUploading,
                                       error: &coordinationError) { archive in
            copyResult = Result { try manager.copyItem(at: archive, to: url) }
        }
        if let coordinationError { throw coordinationError }
        try copyResult.get()
        completed = true
        return url
    }

    static func columns(vehicle: Vehicle, kind: CSVRecordKind) -> [String] {
        let columns = ["Date", "Odometer (\(vehicle.distanceUnit.abbreviated))"]
        switch kind {
        case .maintenance:
            return ["Date", "Services Performed", "Odometer (\(vehicle.distanceUnit.abbreviated))", "Total Cost", "Note"]
        case .repairs:
            return columns + ["Name", "Total Cost", "Category", "Note"]
        case .fillups:
            return columns + [
                "Fuel (\(vehicle.volumeUnit.exportAbbreviation))",
                "Cost per \(vehicle.volumeUnit.exportAbbreviation)", "Total Cost", "Fill Type",
                "Trip Distance (\(vehicle.distanceUnit.abbreviated))",
                "Fuel Economy (\(vehicle.fuelEconomyUnit.displayName))", "Note"
            ]
        }
    }

    static func csv(vehicle: Vehicle, kind: CSVRecordKind) -> String {
        var rows: [(date: Date, fields: [String])] = []
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"

        if kind != .fillups {
            for entry in vehicle.serviceAndRepairTimeline {
                let date = formatter.string(from: entry.date)
                let odometer = entry.odometer.formatted()
                let fields: [String]
                switch entry.type {
                case .serviceRecord(let record):
                    guard kind == .maintenance else { continue }
                    fields = [date, serviceNames(record.service.map { [$0.name] } ?? []), odometer, record.cost?.asCurrency() ?? "", record.note]
                case .serviceLog(let log):
                    guard kind == .maintenance else { continue }
                    let services = serviceNames(log.sortedServicesArray.map { $0.name })
                    fields = [date, services, odometer, log.cost?.asCurrency() ?? "", log.note]
                case .repair(let repair):
                    guard kind == .repairs else { continue }
                    fields = [
                        date, odometer, repair.name, repair.cost?.asCurrency() ?? "",
                        repair.category?.name ?? "", repair.note
                    ]
                }
                rows.append((entry.date, fields))
            }
        } else {
            for fillup in vehicle.sortedFillupsArray {
                rows.append((fillup.date, [
                    formatter.string(from: fillup.date), fillup.odometer.formatted(),
                    fuelVolume(fillup.volume), unitCost(fillup.pricePerUnit),
                    fillup.totalCost?.asCurrency() ?? "",
                    fillup.fillType.rawValue, String(fillup.tripDistance),
                    String(format: "%.1f", locale: Locale(identifier: "en_US_POSIX"), fillup.fuelEconomy()),
                    fillup.note
                ]))
            }
        }
        rows.sort {
            if $0.date != $1.date { return $0.date > $1.date }
            return $0.fields.lexicographicallyPrecedes($1.fields)
        }
        return ([columns(vehicle: vehicle, kind: kind)] + rows.map(\.fields))
            .map { $0.map(escape).joined(separator: ",") }
            .joined(separator: "\r\n") + "\r\n"
    }

    // Quote names containing list delimiters so a future importer can distinguish
    // a single "Oil, filter" service from two services. The outer CSV is escaped separately.
    static func serviceNames(_ names: [String]) -> String {
        names.map { name in
            name.contains(where: { ",\"\r\n".contains($0) }) ? escape(name) : name
        }.joined(separator: ", ")
    }

    static func unitCost(_ value: Double?, locale: Locale = .current) -> String {
        guard let value else { return "" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        // Compare the shortest decimal representation, not a tolerance that can
        // mistake a longer calculated price for an entered three-decimal price.
        let decimal = Decimal(string: String(value), locale: Locale(identifier: "en_US_POSIX"))
        let fractionDigits = decimal.map { max(0, -$0.exponent) } ?? 0
        let digits = fractionDigits == 3 ? 3 : 2
        formatter.minimumFractionDigits = digits
        formatter.maximumFractionDigits = digits
        return formatter.string(from: NSNumber(value: value)) ?? ""
    }

    // Match the fuel-entry form's maximum precision and remove conversion noise.
    // Original trailing zeros are not retained by the model.
    static func fuelVolume(_ value: Double) -> String {
        value.formatted(.number.locale(Locale(identifier: "en_US_POSIX"))
            .grouping(.never).precision(.fractionLength(0...3)))
    }

    static func escape(_ value: String) -> String {
        "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
