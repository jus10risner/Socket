//
//  AddEditServiceView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import SwiftUI

struct AddEditServiceView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var settings: AppSettings
    @StateObject var draftService = DraftService()
    let vehicle: Vehicle?
    let service: Service?
    var onDelete: (() -> Void)?
    
    init(vehicle: Vehicle? = nil, service: Service? = nil, onDelete: (() -> Void)? = nil) {
        self.vehicle = vehicle
        self.service = service
        self.onDelete = onDelete
        
        _draftService = StateObject(wrappedValue: DraftService(service: service))
    }
    
    @FocusState var isInputActive: Bool
    
    @State private var showingDuplicateNameError = false
    @State private var selectedInterval: ServiceIntervalTypes = .distance
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Service Name (e.g. Oil Change)", text: $draftService.name)
                        .textInputAutocapitalization(.words)
                        .focused($isInputActive)
                } header: {
                    if let vehicle {
                        Text(vehicle.name)
                            .font(.body)
                            .frame(maxWidth: .infinity)
                    }
                }
                .headerProminence(.increased)
                
                Section(footer: Text("Check your owner's manual for recommended service intervals.")) {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("What determines when this service is due?")
                            .font(.subheadline.bold())
                        
                        Picker("Track service by", selection: $selectedInterval) {
                            ForEach(ServiceIntervalTypes.allCases, id: \.self) {
                                Text($0.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.vertical, 5)
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("This service should be performed every:")
                            .font(.subheadline.bold())
                        
                        Group {
                            switch selectedInterval {
                            case .distance:
                                HStack {
                                    TextField("5,000", value: $draftService.distanceInterval, format: .number.decimalSeparator(strategy: .automatic))
                                        .fixedSize()
                                    Text(settings.distanceUnit.abbreviated)
                                }
                            case .time:
                                HStack {
                                    TextField("6", value: $draftService.timeInterval, format: .number)
                                        .fixedSize()
                                    
                                    MonthsYearsToggle(monthsInterval: $draftService.monthsInterval, timeInterval: Int(draftService.timeInterval ?? 0))
                                }
                            case .both:
                                VStack(alignment: .leading) {
                                    HStack {
                                        TextField("5,000", value: $draftService.distanceInterval, format: .number.decimalSeparator(strategy: .automatic))
                                            .fixedSize()
                                        Text("\(settings.distanceUnit.abbreviated) or")
                                        TextField("6", value: $draftService.timeInterval, format: .number)
                                            .fixedSize()
                                        
                                        MonthsYearsToggle(monthsInterval: $draftService.monthsInterval, timeInterval: Int(draftService.timeInterval ?? 0))
                                    }
                                }
                            }
                        }
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.center)
                        .keyboardType(.numberPad)
                    }
                    .padding(.vertical, 5)
                }
               
                Section(header: Text("Service Note"), footer: Text("Add info that you want to reference each time this service is performed (e.g. oil type, filter number)")) {
                    TextField("Optional", text: $draftService.serviceNote, axis: .vertical)
//                    TextEditor(text: $draftService.serviceNote)
//                        .frame(minHeight: 50)
//                        .focused($isInputActive)
                }
                
                if onDelete != nil {
                    Button("Delete", role: .destructive) {
                        showingDeleteAlert = true
                    }
                }
                
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(service != nil ? "Edit Service" : "New Maintenance Service")
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
                    Button("Done") {
                        if let service {
                            service.updateAndSave(draftService: draftService, selectedInterval: selectedInterval)
                        } else if let vehicle {
                            if vehicle.sortedServicesArray.contains(where: { service in service.name == draftService.name }) {
                                showingDuplicateNameError = true
                            } else {
                                vehicle.addNewService(draftService: draftService, selectedInterval: selectedInterval)
                            }
                        }
                        
                        dismiss()
                    }
                    .disabled(draftService.canBeSaved ? false : true)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
            }
            .onAppear {
                if service != nil {
                    if draftService.distanceInterval != 0 && draftService.timeInterval == 0 {
                        selectedInterval = .distance
                    } else if draftService.timeInterval != 0 && draftService.distanceInterval == 0 {
                        selectedInterval = .time
                    } else {
                        selectedInterval = .both
                    }
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
}

#Preview {
    let context = DataController.preview.container.viewContext
    
    AddEditServiceView(vehicle: Vehicle(context: context), service: Service(context: context))
        .environmentObject(AppSettings())
}
