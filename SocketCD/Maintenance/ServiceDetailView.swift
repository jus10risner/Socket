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
    @State private var showingAlert = false
    
    var body: some View {
        serviceDetails
    }
    
    
    // MARK: - Views
    
    private var serviceDetails: some View {
        List {
            Section {
                VStack(alignment: .leading) {
                    HStack {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(service.name)
                                .font(.title2.bold())
                                .foregroundStyle(Color.primary)
                                .multilineTextAlignment(.leading)
                            
                            Text("Due every \(distanceIntervalText)\(eitherOr)\(timeIntervalText)")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                        }
                        .padding(.vertical, 5)
                        .accessibilityElement(children: .combine)
                        
                        Spacer()
                        
                        serviceMenu
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Next Due:")
                            .bold()
                        
                        if service.sortedServiceRecordsArray.isEmpty == false {
                            serviceNextDueInfo
                        }
                    }
                    .padding(.vertical, 5)
                    .font(.subheadline)
                }
            }
            
            
            if service.note != "" {
                Section("Service Note") {
                    Text(service.note)
                }
                .textCase(nil)
            }
            
            if !service.sortedServiceRecordsArray.isEmpty {
                serviceHistory
            } else {
                serviceRecordHint
            }
        }
        .navigationTitle("Service Details")
//        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddRecord) {
            AddRecordView(vehicle: vehicle, service: service)
        }
        .sheet(isPresented: $showingEditService) {
            EditServiceView(vehicle: vehicle, service: service)
        }
        .alert("Delete Service", isPresented: $showingAlert) {
            Button("Delete", role: .destructive) {
                service.delete()
                
                // Cancels any pending notifications
                service.cancelPendingNotifications()
                
                dismiss()
            }
            
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("\nPermanently delete this service and all of its records? This cannot be undone.")
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showingAddRecord = true
                } label: {
                    Image(systemName: "plus.square.on.square")
                        .accessibilityLabel("Add a Service Record")
                }
            }
        }
    }
    
    // Menu, with options to edit or delete a service
    private var serviceMenu: some View {
        Menu {
            Button {
                showingEditService = true
            } label: {
                Label("Edit Service Info", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                showingAlert = true
            } label: {
                Label("Delete Service", systemImage: "trash")
            }
        } label: {
            Label("Service Options", systemImage: "ellipsis.circle")
                .font(.title2)
                .labelStyle(.iconOnly)
        }
    }
    
    // String, describing when a service is due next (includes odometerSymbol, which is why this doesn't return a String)
    private var serviceNextDueInfo: some View {
        Group {
            if service.timeInterval != 0 && service.distanceInterval != 0 {
                HStack(spacing: 2) {
                    odometerSymbol
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        VStack(spacing: 2) {
                            Text("\(service.odometerDue?.formatted() ?? "-") \(settings.shortenedDistanceUnit)")
                        }
                        
                        Text("or")
                        
                        VStack(spacing: 2) {
                            Text("\(service.dateDue?.formatted(date: .numeric, time: .omitted) ?? "-")")
                        }
                    }
                }
            } else if service.distanceInterval != 0 && service.timeInterval == 0 {
                HStack(spacing: 2) {
                    odometerSymbol
                    
                    Text("\(service.odometerDue?.formatted() ?? "-") \(settings.shortenedDistanceUnit)")
                }
            } else if service.timeInterval != 0 && service.distanceInterval == 0 {
                VStack {
                    Text("\(service.dateDue?.formatted(date: .numeric, time: .omitted) ?? "-")")
                }
            }
        }
//        .font(.subheadline)
        .accessibilityElement(children: .combine)
    }
    
    // Simple graphic, to precede an odometer reading
    private var odometerSymbol: some View {
        Text("ODO")
            .font(.caption.bold())
            .padding(.horizontal, 2)
            .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder())
            .accessibilityLabel("Odometer")
    }
    
    // Service History section
    private var serviceHistory: some View {
        Section {
            ForEach(service.sortedServiceRecordsArray, id: \.id) { record in
                NavigationLink {
                    RecordDetailView(record: record, vehicle: vehicle, service: service)
                } label: {
                    // Using HStack, because iOS 15 doesn't show badge text at all, if Text("").badge("") is used
                    HStack {
                        Text("\(record.odometer) \(settings.shortenedDistanceUnit)")
                        
                        Spacer()
                        
                        Text("\(record.date.formatted(date: .numeric, time: .omitted))")
                            .foregroundStyle(Color.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        } header: {
            HStack(spacing: 3) {
                Image(systemName: "clock.arrow.circlepath")
                    .accessibilityHidden(true)
                
                Text("Service History")
            }
            .font(.footnote)
            .foregroundStyle(Color.secondary)
        }
        .textCase(nil)
    }
    
    // Hint for adding a new service record
    private var serviceRecordHint: some View {
        Section {
            HStack(spacing: 3) {
                Text("Tap")
                
                Button {
                    showingAddRecord = true
                } label: {
                    Label("Add Service Record", systemImage: "plus.square.on.square")
                        .font(.title3)
                        .labelStyle(.iconOnly)
                }
                
                Text("to add a new service record")
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .font(.subheadline)
            .foregroundStyle(.white)
        }
        .listRowBackground(Color(.socketPurple))
    }
    
    
    // MARK: - Computed Properties
    
    // Time interval between services (if provided), expressed as string
    private var timeIntervalText: String {
        if service.timeInterval != 0 {
            let timeScale = service.monthsInterval
            
            if timeScale == true {
                return "\(service.timeInterval) months"
            } else if timeScale == false && service.timeInterval < 2 {
                return "\(service.timeInterval) year"
            } else {
                return "\(service.timeInterval) years"
            }
        } else {
            return ""
        }
    }
    
    // Distance interval between services (if provided), expressed as a string
    private var distanceIntervalText: String {
        if service.distanceInterval != 0 && service.distanceInterval != 0 {
            return "\(service.distanceInterval.formatted()) \(settings.distanceUnit.rawValue)"
        } else {
            return ""
        }
    }
    
    // Omit the word "or" when only a time or distance interval (but not both) is specified
    private var eitherOr: String {
        if service.timeInterval != 0 && service.distanceInterval != 0 {
            return " or "
        } else {
            return ""
        }
    }
}

#Preview {
    ServiceDetailView(service: Service(context: DataController.preview.container.viewContext), vehicle: Vehicle(context: DataController.preview.container.viewContext))
        .environmentObject(AppSettings())
}
