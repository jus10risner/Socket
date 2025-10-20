//
//  ServiceDetailView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import SwiftUI

struct ServiceDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var settings: AppSettings
    @ObservedObject var service: Service
    let vehicle: Vehicle
    
    @State private var showingAddRecord = false
    @State private var showingEditService = false
    
    var body: some View {
        List {
            Section {
                LabeledContent("Next Due") {
                    if !service.sortedServiceRecordsArray.isEmpty {
                        HStack(spacing: 3) {
                            if service.odometerDue != nil {
                                odometerSymbol
                            }
                            
                            Text(serviceNextDueInfo)
                        }
                    } else {
                        Text("Unknown")
                    }
                }
                
                if service.note != "" {
                    LabeledContent("Service Note") {
                        Text(service.note)
                            .textSelection(.enabled)
                    }
                }
            } header: {
                ContentUnavailableView {
                    Text(service.name)
                        .font(.title2.bold())
                } description: {
                    Text("Due every \(service.intervalDescription)")
                } actions: {
                    Button("Edit") {
                        showingEditService = true
                    }
                    .buttonStyle(.bordered)
                }
            }
            .headerProminence(.increased)
            
            if !service.sortedServiceRecordsArray.isEmpty && !service.sortedServiceRecordsArray.contains(where: { $0.serviceLog?.isBaseline == true }) {
                Section("Service History") {
                    ForEach(service.sortedServiceRecordsArray, id: \.id) { record in
                        NavigationLink {
                            RecordDetailView(record: record, vehicle: vehicle, service: service)
                                .tint(settings.accentColor(for: .maintenanceTheme))
                        } label: {
                            LabeledContent("\(record.effectiveOdometer) \(settings.distanceUnit.abbreviated)", value: record.effectiveDate.formatted(date: .numeric, time: .omitted))
                        }
                    }
                }
                .textCase(nil)
            } else {
                serviceRecordHint
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
                Button("Add Service Record", systemImage: "plus.square.on.square") {
                    showingAddRecord = true
                }
                .adaptiveTint()
            }
        }
    }
    
    
    // MARK: - Views
    
    // String describing when a service is due next
    private var serviceNextDueInfo: String {
        var components: [String] = []

        if let odometer = service.odometerDue, service.distanceInterval != 0 {
            let formatted = "\(odometer.formatted()) \(settings.distanceUnit.abbreviated)"
            components.append(formatted)
        }

        if let date = service.dateDue, service.timeInterval != 0 {
            let formatted = date.formatted(date: .numeric, time: .omitted)
            components.append(formatted)
        }

        return components.joined(separator: " or ")
    }
    
    // Simple graphic, to precede an odometer reading
    private var odometerSymbol: some View {
        Text("ODO")
            .font(.caption.bold())
            .padding(.horizontal, 2)
            .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder())
            .accessibilityLabel("Odometer")
    }
    
    // Hint for adding a new service record
    private var serviceRecordHint: some View {
        Section {
            HStack(spacing: 3) {
                Text("Tap")
                
                Button("Add Service Record", systemImage: "plus") {
                    showingAddRecord = true
                }
                .font(.title3)
                .labelStyle(.iconOnly)
                
                Text("to add a new service record")
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .font(.subheadline)
            .foregroundStyle(.white)
            .accessibilityElement()
            .accessibilityLabel("Tap the Add Service Record button, to add a service record")
        }
        .listRowBackground(Color(.socketPurple))
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
        .environmentObject(AppSettings())
}
