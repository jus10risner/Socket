//
//  CustomInfoCard.swift
//  SocketCD
//
//  Created by Justin Risner on 9/10/26.
//

import CoreData
import SwiftUI

struct CustomInfoCard: View {
    @ObservedObject var vehicle: Vehicle
    let settings = AppSettingsStore.shared
    
    @Binding var activeSheet: ActiveSheet?
    @Binding var selectedSection: AppSection?

    @FetchRequest private var customInfo: FetchedResults<CustomInfo>

    init(vehicle: Vehicle, activeSheet: Binding<ActiveSheet?>, selectedSection: Binding<AppSection?>) {
        self.vehicle = vehicle
        self._activeSheet = activeSheet
        self._selectedSection = selectedSection
        self._customInfo = FetchRequest(
            entity: CustomInfo.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \CustomInfo.label_, ascending: true)],
            predicate: NSPredicate(format: "vehicle == %@", vehicle)
        )
    }
    
    var body: some View {
        DashboardCard(
            title: "Custom Info",
            color: settings.selectedAccent(),
            quickActionTitle: "Add Info",
            accessibilityValue: accessibilityValue,
            accessibilityHint: String(localized: "Opens custom info list")
        ) {
            selectedSection = .customInfo
        } quickAction: {
            activeSheet = .addCustomInfo
        } visual: {
            CardSymbolImage(symbolName: "bookmark.fill", color: settings.selectedAccent())
        } detail: {
            if customInfo.isEmpty {
                CardTextView(
                    headline: "\(vehicle.sortedCustomInfoArray.count)",
                    subheadline: "Items added"
                )
            } else {
                CardTextView(
                    headline: "No Custom Info Added",
                    subheadline: "Save the details that matter to you"
                )
            }
        }
    }
    
    private var accessibilityValue: String {
        let count = vehicle.sortedCustomInfoArray.count
        
        if count > 0 {
            return String(localized: "\(count) items saved")
        } else {
            return String(localized: "No items saved")
        }
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345
    
    return CustomInfoCard(vehicle: vehicle, activeSheet: .constant(nil), selectedSection: .constant(nil))
}
