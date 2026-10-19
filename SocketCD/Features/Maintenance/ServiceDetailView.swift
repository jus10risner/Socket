//
//  ServiceDetailView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import SwiftUI

struct ServiceDetailView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var service: Service
    let vehicle: Vehicle
    
    @State private var showingAddRecord = false
    @State private var showingEditService = false
    
    var body: some View {
        List {
            FormHeaderView(symbolName: AppSection.maintenance.symbol(), primaryText: service.name, secondaryText: "Due every \(service.intervalDescription)", accentColor: AppSection.maintenance.color) {
                Button("Edit") {
                    showingEditService = true
                }
                .tint(AppSection.maintenance.color)
            }
            
            Section {
                LabeledContent("Next Due") {
                    if !service.sortedServiceRecordsArray.isEmpty {
                        Text(serviceNextDueInfo)
                    } else {
                        Text("Not set")
                    }
                }
                
                if service.note != "" {
                    LabeledContent("Service Note") {
                        Text(service.note)
                            .textSelection(.enabled)
                    }
                }
            }
            
            if !service.serviceHistoryRecordsArray.isEmpty {
                Section("Service History") {
                    ForEach(service.serviceHistoryRecordsArray, id: \.id) { record in
                        NavigationLink {
                            RecordDetailView(record: record, vehicle: vehicle, service: service)
                        } label: {
                            LabeledContent {
                                Text("\(record.effectiveOdometer.formatted()) \(vehicle.distanceUnit.abbreviated)")
                                    .foregroundStyle(.secondary)
                            } label: {
                                Text(record.effectiveDate, format: .dateTime.month(.abbreviated).day().year())
                            }
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(
                                "\(record.effectiveDate.formatted(date: .long, time: .omitted)), odometer \(record.effectiveOdometer.formatted()) \(vehicle.distanceUnit.rawValue)"
                            )
                        }
                    }
                }
                .textCase(nil)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddRecord) {
            AddEditRecordView(service: service, vehicle: vehicle)
        }
        .sheet(isPresented: $showingEditService) {
            AddEditServiceView(vehicle: vehicle, service: service) {
                dismiss()
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add Service Log", systemImage: "plus") {
                    showingAddRecord = true
                }
                .tint(.primary)
            }
        }
    }
    
    
    // MARK: - Views
    
    // String describing when a service is due next
    private var serviceNextDueInfo: String {
        var components: [String] = []

        if let odometer = service.odometerDue, service.distanceInterval != 0 {
            let formatted = "\(odometer.formatted()) \(vehicle.distanceUnit.abbreviated)"
            components.append(formatted)
        }

        if let date = service.dateDue, service.timeInterval != 0 {
            let formatted = date.formatted(date: .numeric, time: .omitted)
            components.append(formatted)
        }

        return components.joined(separator: " or ")
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345
    
    let service = Service(context: context)
    service.name = "Oil Change"
    service.note = "Filter: AX204"
    
    return ServiceDetailView(service: service, vehicle: vehicle)
}
