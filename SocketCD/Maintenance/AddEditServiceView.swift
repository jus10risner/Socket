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
    let settings = AppSettings.shared
    
    // MARK: - State
    @StateObject var draftService = DraftService()
    @StateObject var draftServiceLog = DraftServiceLog()
    @FocusState var isInputActive: Bool
    @State private var showingDuplicateNameError = false
    @State private var loggingService = true
    @State private var showingDeleteAlert = false
    @State private var showingMoreInfo = false
    
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
                FormHeaderView(symbolName: "book.and.wrench", primaryText: service != nil ? "Edit Service" : "New Service", accentColor: Color.maintenanceTheme)
                
                Section {
                    TextField("Service Name (e.g. Oil Change)", text: $draftService.name)
                        .textInputAutocapitalization(.words)
                        .focused($isInputActive)
                }
                
                Section {
                    formItem(headline: "This service should be performed every:", subheadline: "Enter a distance, a time interval, or both.") {
                        ViewThatFits(in: .horizontal) {
                            HStack {
                                TextField("5,000", text: optionalIntFieldBinding($draftService.distanceInterval))
                                    .keyboardType(.numberPad)
                                    .fixedSize()
                                    .accessibilityLabel("Distance interval")
                                    .accessibilityHint("Enter the number of " + settings.distanceUnit.rawValue)

                                Text("\(String(describing: settings.distanceUnit.abbreviated)) or")
                                    .accessibilityHidden(true)

                                TextField("6", text: optionalIntFieldBinding($draftService.timeInterval))
                                    .keyboardType(.numberPad)
                                    .fixedSize()
                                    .accessibilityLabel("Time interval")
                                    .accessibilityHint("Enter the number of months or years")

                                MonthsYearsToggle(
                                    monthsInterval: $draftService.monthsInterval,
                                    timeInterval: Int(draftService.timeInterval ?? 0)
                                )
                            }
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                            
                            VStack(alignment: .leading) {
                                HStack {
                                    TextField("5,000", text: optionalIntFieldBinding($draftService.distanceInterval))
                                        .keyboardType(.numberPad)
                                        .fixedSize()
                                        .accessibilityLabel("Distance interval")
                                        .accessibilityHint("Enter the number of " + settings.distanceUnit.rawValue)
                                    
                                    Text("\(String(describing: settings.distanceUnit.abbreviated)) or")
                                        .accessibilityHidden(true)
                                }

                                HStack {
                                    TextField("6", text: optionalIntFieldBinding($draftService.timeInterval))
                                        .keyboardType(.numberPad)
                                        .fixedSize()
                                        .accessibilityLabel("Time interval")
                                        .accessibilityHint("Enter the number of months or years")
                                    
                                    MonthsYearsToggle(
                                        monthsInterval: $draftService.monthsInterval,
                                        timeInterval: Int(draftService.timeInterval ?? 0)
                                    )
                                }
                            }
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                        }
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
                        
                        if loggingService {
                            formItem(headline: "When was this service last performed?", subheadline: "This will be added to service history.") {
                                
                                DatePicker("Date", selection: $draftServiceLog.date, displayedComponents: .date)
                                    .foregroundStyle(Color.secondary)
                            }
                            
                            LabeledInput(label: "Odometer") {
                                TextField("Required", value: $draftServiceLog.odometer, format: .number.decimalSeparator(strategy: .automatic))
                                    .keyboardType(.numberPad)
                            }
                            
                            LabeledInput(label: "Cost") {
                                TextField("Optional", value: $draftServiceLog.cost, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                                    .keyboardType(.decimalPad)
                            }
                        } else {
                            formItem(headline: "Define a starting point for this service.", hasInfoButton: true, subheadline: "This will not be added to service history.") {
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
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if service == nil {
                    // Show keyboard automatically, when adding a new service
                    DispatchQueue.main.async {
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
                                return
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
                        .adaptiveTint()
                }
            }
            .alert("Delete Service", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let service {
                        let ids = [
                            service.timeBasedNotificationIdentifier,
                            service.distanceBasedNotificationIdentifier
                        ]
                        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
                        
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
    
    // MARK: - Methods
    
    // Defines the header and padding for the service interval and 'Start Tracking From' sections
    private func formItem<Content: View>(headline: String, hasInfoButton: Bool = false, subheadline: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            VStack(alignment: .leading) {
                HStack {
                    Text(headline)
                        .font(.subheadline.bold())
                        .accessibilityHint(subheadline ?? "")
                    
                    if hasInfoButton {
                        Button("More Info", systemImage: "info.circle") {
                            isInputActive = false
                            showingMoreInfo = true
                        }
                        .labelStyle(.iconOnly)
                        .foregroundStyle(settings.selectedAccent())
                        .buttonStyle(.plain)
                        .popover(isPresented: $showingMoreInfo) {
                            PopoverContent(text: """
                                If this is a new vehicle or you don’t know when this service was last performed, select this option.
                                
                                Socket will use the values you enter to calculate when the service is due.
                                """)
                        }
                    }
                }
                if let subheadline {
                    Text(subheadline)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                }
            }
            
            content()
        }
        .padding(.vertical, 5)
    }
    
    // Allows optional Int values to be displayed as blank fields if the value is either nil or 0 (for better UX)
    private func optionalIntFieldBinding(_ value: Binding<Int?>) -> Binding<String> {
        Binding(
            get: {
                guard let v = value.wrappedValue, v != 0 else { return "" }
                return String(v)
            },
            set: { newValue in
                if let intValue = Int(newValue), intValue != 0 {
                    value.wrappedValue = intValue
                } else {
                    value.wrappedValue = nil
                }
            }
        )
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
}

