//
//  Vehicle+helper.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import CoreData
import SwiftUI

extension Vehicle {
    
    var name: String {
        get { name_ ?? "" }
        set { name_ = newValue }
    }
    
    var odometer: Int {
        get { Int(odometer_) }
        set { odometer_ = Int64(newValue) }
    }
    
    var colorComponents: [CGFloat]? {
        get { colorComponents_ ?? [0.3060232996940613, 0.2939836084842682, 0.4549291133880615, 1.0] }
        set { colorComponents_ = newValue }
    }
    
    var backgroundColor: Color {
        if let colorComponents {
            return Color(.sRGB, red: colorComponents[0], green: colorComponents[1], blue: colorComponents[2], opacity: colorComponents[3])
        } else {
            return Color.socketPurple
        }
    }
    
    var sortedCustomInfoArray: [CustomInfo] {
        let set = customInfo as? Set<CustomInfo> ?? []
        
        return set.sorted {
            $0.label < $1.label
        }
    }
    
    var sortedRepairsArray: [Repair] {
        let set = repairs as? Set<Repair> ?? []
        
        return set.sorted {
            $0.date > $1.date
        }
    }
    
    var sortedFillupsArray: [Fillup] {
        let set = fillups as? Set<Fillup> ?? []
        
        return set.sorted {
            $0.date > $1.date
        }
    }
    
    var sortedServicesArray: [Service] {
        let set = services as? Set<Service> ?? []
        
        return set.sorted {
            $0.name < $1.name
        }
    }
    
    
    
    // MARK: - Computed Properties
    
    // Returns the fuel volume unit for the user's selected fuel economy units, in App Settings
    var volumeUnit: String {
        let settings = AppSettings()
        
        if settings.fuelEconomyUnit == .mpg {
            return "Gallon"
        } else {
            return "Liter"
        }
    }
    
    
    // MARK: - CRUD Methods
    
    func updateAndSave(draftVehicle: DraftVehicle) {
        let context = DataController.shared.container.viewContext
        let colorComponents = UIColor(draftVehicle.selectedColor).cgColor.components
        
        self.name = draftVehicle.name
        self.odometer = draftVehicle.odometer ?? 0
        self.colorComponents = colorComponents
        self.photo = draftVehicle.photo
        
        try? context.save()
    }
    
    func delete() {
        let context = DataController.shared.container.viewContext
        
        context.delete(self)
        try? context.save()
    }
    
    func addNewService(draftService: DraftService, selectedInterval: ServiceIntervalTypes) {
        let context = DataController.shared.container.viewContext
        
        if selectedInterval == .distance {
            draftService.timeInterval = 0
        } else if selectedInterval == .time {
            draftService.distanceInterval = 0
        }
        
        let newService = Service(context: context)
        newService.vehicle = self
        newService.id = UUID()
        newService.name = draftService.name
        newService.distanceInterval = draftService.distanceInterval ?? 0
        newService.timeInterval = draftService.timeInterval ?? 0
        newService.monthsInterval = draftService.monthsInterval
        newService.note = draftService.serviceNote
        newService.distanceBasedNotificationIdentifier = UUID().uuidString
        newService.timeBasedNotificationIdentifier = UUID().uuidString
        
        try? context.save()
    }
    
    func addNewRepair(draftRepair: DraftRepair) {
        let context = DataController.shared.container.viewContext
        let newRepair = Repair(context: context)
        newRepair.vehicle = self
        newRepair.id = UUID()
        newRepair.date = draftRepair.date
        newRepair.name = draftRepair.name
        newRepair.odometer = draftRepair.odometer ?? 0
        newRepair.cost = draftRepair.cost
        newRepair.note = draftRepair.note
        newRepair.photos = NSSet(array: draftRepair.photos)
        
        if let odometer = draftRepair.odometer {
            if odometer > self.odometer {
                self.odometer = odometer
            }
        }
        
        try? context.save()
    }
    
    func addNewFillup(draftFillup: DraftFillup) {
        let context = DataController.shared.container.viewContext
        let newFillup = Fillup(context: context)
        newFillup.vehicle = self
        newFillup.id = UUID()
        newFillup.date = draftFillup.date
        newFillup.odometer = draftFillup.odometer ?? 0
        newFillup.volume = draftFillup.volume ?? 0
        newFillup.pricePerUnit = draftFillup.fillupCostPerUnit
        newFillup.fillType = draftFillup.fillType
        newFillup.note = draftFillup.note
        newFillup.photos = NSSet(array: draftFillup.photos)
        
        if let odometer = draftFillup.odometer {
            if odometer > self.odometer {
                self.odometer = odometer
            }
        }
        
        try? context.save()
    }
    
    func addNewInfo(draftCustomInfo: DraftCustomInfo) {
        let context = DataController.shared.container.viewContext
        let newCustomInfo = CustomInfo(context: context)
        newCustomInfo.vehicle = self
        newCustomInfo.id = UUID()
        newCustomInfo.label = draftCustomInfo.label
        newCustomInfo.detail = draftCustomInfo.detail
        newCustomInfo.note = draftCustomInfo.note
        newCustomInfo.photos = NSSet(array: draftCustomInfo.photos)
        
        try? context.save()
    }
    
    
    // MARK: - Other Methods
    
    // Takes a Double value, and converts it into a currency string (e.g. 1.23 -> "$1.23")
    func convertToCurrency(value: Double) -> String {
        var returnString = ""
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        
        if let returnValue = formatter.string(from: NSNumber(value: value)) {
            returnString = returnValue
        }
        
        return returnString
    }
}
