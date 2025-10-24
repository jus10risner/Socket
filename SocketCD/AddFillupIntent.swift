//
//  AddFillupIntent.swift
//  SocketCD
//
//  Created by Justin Risner on 10/24/25.
//

import AppIntents
import CoreData
import SwiftUI

struct Shortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddFillupIntent(),
            phrases: [
                "Add a fill-up to \(.applicationName)"
            ],
            shortTitle: "Add Fill-up",
            systemImageName: "fuelpump"
        )
    }
}

struct AddFillupIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Fill-up"
    static var description = IntentDescription("Add a fill-up to a vehicle.")

    @Parameter(
        title: "Vehicle",
        requestValueDialog: "Which vehicle is this fill-up for?"
    )
    var selectedVehicle: VehicleEntity

    @Parameter(
        title: "Odometer",
        requestValueDialog: "What is the odometer reading?"
    )
    var odometer: Int

    @Parameter(
        title: "Fuel Volume",
        requestValueDialog: "How many \(AppSettings.shared.fuelEconomyUnit.volumeUnit.lowercased())s of fuel did you add?"
    )
    var fuelVolume: Double

    @Parameter(
        title: "Cost",
        requestValueDialog: "What is the cost per \(AppSettings.shared.fuelEconomyUnit.volumeUnit.lowercased()) of fuel?"
    )
    var costPerUnit: Double

    static var parameterSummary: some ParameterSummary {
        Summary("Add a fill-up to \(\.$selectedVehicle) with odometer \(\.$odometer), fuel \(\.$fuelVolume), cost \(\.$costPerUnit)")
    }
    
    func defaultResult() async throws -> some IntentResult {
        let context = DataController.shared.container.viewContext
        let request: NSFetchRequest<Vehicle> = Vehicle.fetchRequest()
        let vehicles = try context.fetch(request)

        // Pre-fill the selectedVehicle if only one exists
        if vehicles.count == 1, let id = vehicles.first?.id, let name = vehicles.first?.name {
            selectedVehicle = VehicleEntity(id: id, name: name)
        }

        // Return a plain result; system will now skip prompting for selectedVehicle if it has a value
        return .result()
    }

    @MainActor
    func perform() async throws -> some ProvidesDialog {
        // Resolve the Core Data Vehicle from the selected AppEntity
        let context = DataController.shared.container.viewContext
        let vehicleFetch: NSFetchRequest<Vehicle> = Vehicle.fetchRequest()
        vehicleFetch.fetchLimit = 1
        vehicleFetch.predicate = NSPredicate(format: "id == %@", selectedVehicle.id as CVarArg)

        guard let vehicle = try context.fetch(vehicleFetch).first else {
            throw IntentError.vehicleNotFound
        }

        // Create and save a Fillup
        let fillup = Fillup(context: context)
        fillup.id = UUID()
        fillup.date = Date()
        fillup.odometer = odometer
        fillup.volume = fuelVolume
        fillup.pricePerUnit = costPerUnit
        fillup.vehicle = vehicle

        try context.save()

        let dialog = IntentDialog("Fill-up Added!")
        
        return .result(dialog: dialog)
    }
}

enum IntentError: Error, CustomLocalizedStringResourceConvertible {
    case vehicleNotFound

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .vehicleNotFound:
            "The selected vehicle could not be found."
        }
    }
}

struct VehicleEntity: AppEntity {
    typealias ID = UUID

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Vehicle"

    // This string is shown in UI when listing this entity.
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(stringLiteral: name)
    }

    // AppEntity identity
    let id: UUID
    let name: String

    // If you want to show additional fields in selection rows, you can add @Property
    // wrappers. Keep in mind @Property is for AppEntity properties shown to the user.
    // For the identity and display, plain stored properties are fine.
    static var defaultQuery = VehicleEntityQuery()
}

struct VehicleEntityQuery: EntityQuery {
    func suggestedEntities() async throws -> [VehicleEntity] {
        try await fetchAllVehicles()
    }
    
    func entities(for identifiers: [VehicleEntity.ID]) async throws -> [VehicleEntity] {
        let context = DataController.shared.container.viewContext
        let request: NSFetchRequest<Vehicle> = Vehicle.fetchRequest()
        request.predicate = NSPredicate(format: "id IN %@", identifiers as [UUID])

        let vehicles = try context.fetch(request)
        return vehicles.compactMap { v in
            guard let id = v.id else { return nil }
            return VehicleEntity(id: id, name: v.name)
        }
    }
    
    private func fetchAllVehicles() async throws -> [VehicleEntity] {
        let context = DataController.shared.container.viewContext
        let request: NSFetchRequest<Vehicle> = Vehicle.fetchRequest()
        let vehicles = try context.fetch(request)
        return vehicles.compactMap { v in
            guard let id = v.id else { return nil }
            return VehicleEntity(id: id, name: v.name)
        }
    }
}
