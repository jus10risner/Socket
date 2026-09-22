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
    @ObservedObject private var settings = AppSettingsStore.shared
    
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
                    headline: "Organize Important Details",
                    subheadline: "Save information for easy access"
                )
            } else {
                CardTextView(
                    headline: savedDetailsHeadline,
                    subheadline: savedLabelsSummary
                )
            }
        }
    }
    
    private var savedDetailsHeadline: String {
        let count = customInfo.count
        if count == 1 {
            return String(localized: "1 Saved Detail")
        } else {
            return String(localized: "\(count) Saved Details")
        }
    }

    private var savedLabelsSummary: String {
        let labels = customInfo.map(\.label)

        switch labels.count {
        case 0:
            return ""
        case 1:
            return labels[0]
        case 2:
            return labels.formatted(.list(type: .and, width: .short))
        default:
            let remainingCount = labels.count - 2
            return String(localized: "\(labels[0]), \(labels[1]) & \(remainingCount) more")
        }
    }
    
    private var accessibilityValue: String {
        guard !customInfo.isEmpty else {
            return String(localized: "No vehicle details saved")
        }

        return String(localized: "\(savedDetailsHeadline). \(savedLabelsSummary)")
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345
    
    return CustomInfoCard(vehicle: vehicle, activeSheet: .constant(nil), selectedSection: .constant(nil))
}
