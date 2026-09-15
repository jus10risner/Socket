//
//  FillupsCard.swift
//  SocketCD
//
//  Created by Justin Risner on 10/1/25.
//

import CoreData
import SwiftUI

struct FillupsCard: View {
    @ObservedObject var vehicle: Vehicle
    
    @Binding var activeSheet: ActiveSheet?
    @Binding var selectedSection: AppSection?
    let settings = AppSettingsStore.shared
    
    @FetchRequest var fillups: FetchedResults<Fillup>
    
    init(vehicle: Vehicle, activesheet: Binding<ActiveSheet?>, selectedSection: Binding<AppSection?>) {
        self.vehicle = vehicle
        self._activeSheet = activesheet
        self._selectedSection = selectedSection
        self._fillups = FetchRequest(
            entity: Fillup.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Fillup.date_, ascending: false)],
            predicate: NSPredicate(format: "vehicle == %@", vehicle)
        )
    }
    
    var body: some View {
        DashboardCard(
            title: "Fill-ups",
            color: Color(.fillupsTheme),
            quickActionTitle: "Add Fill-up",
            accessibilityValue: accessibilityValue,
            accessibilityHint: String(localized: "Opens fill-up history")
        ) {
            selectedSection = .fillups
        } quickAction: {
            activeSheet = .addFillup
        } visual: {
            if latestValidFillup != nil {
                TrendArrowView(
                    latestFuelEconomy: latestFuelEconomy,
                    previousFuelEconomy: previousFuelEconomy
                )
            } else {
                CardSymbolImage(symbolName: "fuelpump.fill", color: Color(.fillupsTheme))
            }
        } detail: {
            if let fillup = latestValidFillup {
                CardTextView(
                    headline: "\(Double(fillup.fuelEconomy()).formatted(.number.precision(.fractionLength(1)))) \(settings.fuelEconomyUnit.rawValue)",
                    subheadline: "Last calculated \(formattedFuelEconomyDate(fillup.date))"
                )
            } else {
                CardTextView(
                    headline: "No Fill-ups Logged",
                    subheadline: "Add your first fill-up when you’re ready"
                )
            }
        }
    }
    
    // Returns month/day if the latest fuel economy calculation was less than one year ago; otherwise returns month/day/year
    private func formattedFuelEconomyDate(_ date: Date) -> String {
        if Calendar.current.isDate(date, equalTo: .now, toGranularity: .year) {
            date.formatted(.dateTime.month(.abbreviated).day())
        } else {
            date.formatted(.dateTime.month(.abbreviated).day().year())
        }
    }

    private var latestValidFillup: Fillup? {
        fillups.first { $0.fuelEconomy() > 0 }
    }

    private var validFuelEconomies: [Double] {
        fillups.lazy
            .map { $0.fuelEconomy() }
            .filter { $0 > 0 }
            .prefix(2)
            .map { $0 }
    }

    private var latestFuelEconomy: Double? {
        validFuelEconomies.first
    }

    private var previousFuelEconomy: Double? {
        validFuelEconomies.dropFirst().first
    }

    private var fuelEconomyTrendDescription: String {
        guard let latestFuelEconomy, let previousFuelEconomy else {
            return String(localized: "No fuel economy trend available")
        }

        if latestFuelEconomy > previousFuelEconomy {
            return String(localized: "Fuel economy is trending up")
        } else if latestFuelEconomy < previousFuelEconomy {
            return String(localized: "Fuel economy is trending down")
        } else {
            return String(localized: "Fuel economy is unchanged")
        }
    }

    private var accessibilityValue: String {
        guard let fillup = latestValidFillup else {
            return String(localized: "No fill-ups logged")
        }

        let economy = fillup.fuelEconomy().formatted(.number.precision(.fractionLength(1)))
        let date = formattedFuelEconomyDate(fillup.date)
        return String(localized: "\(economy) \(settings.fuelEconomyUnit.fullName). \(fuelEconomyTrendDescription). Last calculated \(date)")
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345
    
    return FillupsCard( vehicle: vehicle, activesheet: .constant(nil), selectedSection: .constant(nil))
}
