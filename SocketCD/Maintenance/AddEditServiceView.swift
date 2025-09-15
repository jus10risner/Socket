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
    @State private var selectedInterval: ServiceIntervalTypes = .distance
    @State private var loggingService = false
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
                
                Section(footer: Text("Check your owner's manual for recommended service intervals.")) {
                    formItem(headline: "What determines when this service is due?") {
                        Picker("Track service by", selection: $selectedInterval) {
                            ForEach(ServiceIntervalTypes.allCases, id: \.self) {
                                Text($0.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    formItem(headline: "This service should be performed every:") {
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
                }
                
                if service == nil {
                    Section(footer: Text("Service will be tracked from today at your current odometer if no service record is added.")) {
                        formItem(headline: "Add a service record now?") {
                            Picker("", selection: $loggingService.animation()) {
                                Text("No")
                                    .tag(false)
                                
                                Text("Yes")
                                    .tag(true)
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        if loggingService {
                            formItem(headline: "When was this service last performed?") {
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
                    Button("Done") {
                        if let service {
                            service.updateAndSave(draftService: draftService, selectedInterval: selectedInterval)
                        } else if let vehicle {
                            if vehicle.sortedServicesArray.contains(where: { service in service.name == draftService.name }) {
                                showingDuplicateNameError = true
                            } else {
                                if loggingService && draftServiceLog.odometer != nil {
                                    vehicle.addNewService(draftService: draftService, selectedInterval: selectedInterval, initialRecord: draftServiceLog)
                                } else {
                                    vehicle.addNewService(draftService: draftService, selectedInterval: selectedInterval)
                                }
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
    
    private func formItem<Content: View>(headline: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(headline)
                .font(.subheadline.bold())
            
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
