//
//  AddEditServiceView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import SwiftUI

struct AddEditServiceView: View {
    // MARK: - Environment
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var settings: AppSettings
    
    // MARK: - State
    @StateObject var draftService = DraftService()
    @StateObject var draftServiceLog = DraftServiceLog()
    @FocusState var isInputActive: Bool
    @State private var showingDuplicateNameError = false
    @State private var loggingService = true
    @State private var showingDeleteAlert = false
    
    // MARK: - Input
    private let vehicle: Vehicle?
    private let service: Service?
    private let onDelete: (() -> Void)?
    
    // MARK: - Init
    init(vehicle: Vehicle? = nil, service: Service? = nil, onDelete: (() -> Void)? = nil) {
        self.vehicle = vehicle
        self.service = service
        self.onDelete = onDelete
        
        _draftService = StateObject(wrappedValue: DraftService(service: service))
        _draftServiceLog = StateObject(wrappedValue: DraftServiceLog())
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledInput(label: "Service Name") {
                        TextField("e.g. Oil Change", text: $draftService.name)
                            .textInputAutocapitalization(.words)
                            .focused($isInputActive)
                    }
                } header: {
                    if let vehicle {
                        Text(vehicle.name)
                            .font(.body)
                            .frame(maxWidth: .infinity)
                    }
                }
                .headerProminence(.increased)
                
                Section(footer: Text("Track by distance, time, or both — your choice.")) {
                    formItem(headline: "This service should be performed every:") {
                        HStack {
                            TextField("5,000", value: $draftService.distanceInterval, format: .number.decimalSeparator(strategy: .automatic))
                                .fixedSize()
                            
                            Text("\(settings.distanceUnit.abbreviated) or")
                            
                            TextField("6", value: $draftService.timeInterval, format: .number)
                                .fixedSize()
                            
                            MonthsYearsToggle(monthsInterval: $draftService.monthsInterval, timeInterval: Int(draftService.timeInterval ?? 0))
                        }
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.center)
                        .keyboardType(.numberPad)
                    }
                }
                
                if service == nil {
                    Section {
                        formItem(headline: "Start tracking from:") {
                            Picker("", selection: $loggingService.animation()) {
                                Text("Last Service")
                                    .tag(true)
                                
                                Text("Custom")
                                    .tag(false)
                            }
                            .pickerStyle(.segmented)
                        }
//                        
                        if loggingService {
                            formItem(headline: "When was this service last performed?", subheadline: "This will be added to service history.") {
                                
                                DatePicker("Date", selection: $draftServiceLog.date, displayedComponents: .date)
                                    .foregroundStyle(Color.secondary)
                            }
                            
                            LabeledInput(label: "Odometer") {
                                TextField("Required", value: $draftServiceLog.odometer, format: .number.decimalSeparator(strategy: .automatic))
                                    .keyboardType(.numberPad)
                            }
                        } else {
                            formItem(headline: "Define a starting point for this service.", subheadline: "This will not be added to service history.") {
                                DatePicker("Date", selection: $draftServiceLog.date, displayedComponents: .date)
                                    .foregroundStyle(Color.secondary)
                            }
                            
                            LabeledInput(label: "Odometer") {
                                TextField("Required", value: $draftServiceLog.odometer, format: .number.decimalSeparator(strategy: .automatic))
                                    .keyboardType(.numberPad)
                            }
                        }
                    }
                    .textCase(nil)
                    .onChange(of: loggingService) {
                        draftServiceLog.odometer = loggingService ? nil : vehicle?.odometer
                    }
                }
               
                Section {
                    TextField("Service Note", text: $draftService.serviceNote, axis: .vertical)
                }
                
                if onDelete != nil {
                    Button("Delete Service", role: .destructive) {
                        showingDeleteAlert = true
                    }
                }
                
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(service != nil ? "Edit Service" : "New Service")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if service == nil {
                    // Show keyboard after a short delay, when adding a new service
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                        isInputActive = true
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(service != nil ? "Done" : "Add", systemImage: "checkmark") {
                        if let service {
                            service.updateAndSave(draftService: draftService)
                        } else if let vehicle {
                            if vehicle.sortedServicesArray.contains(where: { service in service.name == draftService.name }) {
                                showingDuplicateNameError = true
                            } else if draftServiceLog.odometer != nil {
                                vehicle.addNewService(draftService: draftService, initialRecord: draftServiceLog, isBaseLine: loggingService ? false : true)
                            }
                        }
                        
                        dismiss()
                    }
                    .labelStyle(.adaptive)
                    .disabled(draftService.canBeSaved ? false : true)
                    .disabled(service == nil && draftServiceLog.odometer == nil ? true : false)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark", role: .cancel) { dismiss() }
                        .labelStyle(.adaptive)
                }
            }
            .alert("Delete Service", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let service {
                        service.cancelPendingNotifications()
                        DataController.shared.delete(service)
                    }
                    
                    dismiss()
                    onDelete?()
                }
                
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Permanently delete this service and all of its records? This cannot be undone.")
            }
            .alert("This vehicle already has a service with that name", isPresented: $showingDuplicateNameError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please choose a different name.")
            }
        }
    }
    
    private func formItem<Content: View>(headline: String, subheadline: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            VStack(alignment: .leading) {
                Text(headline)
                    .font(.subheadline.bold())
                if let subheadline {
                    Text(subheadline)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            content()
        }
        .padding(.vertical, 5)
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345
    
    let service = Service(context: context)
    service.name = "Oil Change"
    service.distanceInterval = 5000
    service.timeInterval = 1
    service.monthsInterval = false
    
    return AddEditServiceView(vehicle: vehicle, service: service)
        .environmentObject(AppSettings())
}
