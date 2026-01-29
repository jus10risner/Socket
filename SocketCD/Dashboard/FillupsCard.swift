//
//  FillupsCard.swift
//  SocketCD
//
//  Created by Justin Risner on 10/1/25.
//

import SwiftUI

struct FillupsCard: View {
    @ObservedObject var vehicle: Vehicle
    
    @Binding var activeSheet: ActiveSheet?
    @Binding var selectedSection: AppSection?
    let settings = AppSettings.shared
    
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
        DashboardCard(title: "Fill-ups", systemImage: "fuelpump.fill", accentColor: Color(.fillupsTheme), buttonLabel: "Add Fill-up", buttonSymbol: "plus") {
            activeSheet = .addFillup
        } content: {
            HStack {
                if fillups.count > 0 {
                    TrendArrowView(fillups: fillups)
                }
                
                if let fillup = vehicle.sortedFillupsArray.first {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(fillup.date.formatted(date: .numeric, time: .omitted))
                            .font(.footnote.bold())
                            .foregroundStyle(Color.secondary)
                        
                        Group {
                            if fillup.fuelEconomy() > 0 {
                                Text("\(fillup.fuelEconomy(), format: .number.precision(.fractionLength(1))) \(settings.fuelEconomyUnit.rawValue)")
                            } else {
                                switch fillup.fillType {
                                case .fullTank:
                                    Text(fillup == fillups.last(where: { $0.fillType == .fullTank }) ? "First Full Tank" : "Full Tank")
                                case .partialFill:
                                    Text("Partial Fill")
                                case .missedFill:
                                    Text("Full Tank (Reset)")
                                }
                            }
                        }
                        .font(.headline)
                    }
                } else {
                    Text("Nothing logged yet")
                        .font(.headline)
                        .foregroundStyle(Color.secondary)
                }
            }
        }
        .accessibilityLabel(accessibilityLabel)
        .onTapGesture {
            selectedSection = .fillups
        }
        .accessibilityAction(named: "Add Fill-up", {
            activeSheet = .addFillup
        })
        .accessibilityAction {
            selectedSection = .fillups
        }
    }
    
    // Returns the correct label for VoiceOver to read
    private var accessibilityLabel: String {
        let headline = "Fill-ups: "
        
        if let fillup = vehicle.sortedFillupsArray.first {
            return headline + "Latest fill-up: \(fillup.date.formatted(date: .numeric, time: .omitted)) \(fuelEconomyValue)"
        } else {
            return headline + "Nothing logged yet"
        }
    }
    
    // Returns the fuel economy value to read, if one exists (for VoiceOver)
    private var fuelEconomyValue: String {
        if let fillup = vehicle.sortedFillupsArray.first {
            if fillup.fuelEconomy() > 0 {
                return "\(fillup.fuelEconomy().formatted(.number.precision(.fractionLength(1)))) \(settings.fuelEconomyUnit.fullName)"
            } else {
                switch fillup.fillType {
                case .fullTank:
                    return fillup == fillups.last(where: { $0.fillType == .fullTank }) ? "First Full Tank" : "Full Tank"
                case .partialFill:
                    return "Partial Fill"
                case .missedFill:
                    return "Full Tank (Reset)"
                }
            }
        } else {
            return ""
        }
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345
    
    return FillupsCard( vehicle: vehicle, activesheet: .constant(nil), selectedSection: .constant(nil))
}
