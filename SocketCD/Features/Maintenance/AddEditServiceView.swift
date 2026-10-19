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
    let settings = AppSettingsStore.shared
    
    // MARK: - State
    @StateObject var draftService = DraftService()
    @StateObject var draftServiceLog = DraftServiceLog()
    @FocusState var isInputActive: Bool
    @State private var showingDuplicateNameError = false
    @State private var odometerWarning: OdometerWarning?
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
                FormHeaderView(symbolName: AppSection.maintenance.symbol(), primaryText: service != nil ? "Edit Service" : "New Service", accentColor: AppSection.maintenance.color)
                
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
                                    .accessibilityHint("Enter the number of " + distanceUnit.rawValue)

                                Text("\(distanceUnit.abbreviated) or")
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
                                        .accessibilityHint("Enter the number of " + distanceUnit.rawValue)
                                    
                                    Text("\(distanceUnit.abbreviated) or")
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
                        saveService()
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
            .tint(AppSection.maintenance.color)
            .alert("Delete Service", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let service {
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
            .odometerWarningAlert(
                warning: $odometerWarning,
                entered: draftServiceLog.odometer,
                current: vehicle?.odometer,
                distanceUnit: distanceUnit.abbreviated,
                onConfirm: performServiceSave
            )
        }
        .tint(nil)
    }
    
    // MARK: - Methods

    private var distanceUnit: DistanceUnits {
        vehicle?.distanceUnit ?? service?.vehicle?.distanceUnit ?? settings.distanceUnit
    }

    private func saveService() {
        guard service == nil else {
            performServiceSave()
            return
        }

        guard let vehicle else { return }

        guard !vehicle.sortedServicesArray.contains(where: { $0.name == draftService.name }) else {
            showingDuplicateNameError = true
            return
        }

        if let entered = draftServiceLog.odometer,
           let warning = OdometerValidator.warning(
               entered: entered,
               current: vehicle.odometer,
               context: .historicalRecord
           ) {
            odometerWarning = warning
            return
        }

        performServiceSave()
    }

    private func performServiceSave() {
        if let service {
            service.updateAndSave(draftService: draftService)
        } else if let vehicle, draftServiceLog.odometer != nil {
            vehicle.addNewService(
                draftService: draftService,
                initialRecord: draftServiceLog,
                isBaseLine: !loggingService
            )
        }

        dismiss()
    }
    
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
                        .foregroundStyle(AppSection.maintenance.color)
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


// MARK: - Subviews

private struct MonthsYearsToggle: View {
    @Binding var monthsInterval: Bool
    let timeInterval: Int?
    
    @State private var flipped: Bool = false
    
    @State private var boxRotation = 0.001 // Using 0.0 here causes error: "ignoring singular matrix..." on iOS 16+
    @State private var textRotation = 0.0 // ""
    
    var body: some View {
        Button {
            flipButton()
            monthsInterval.toggle()
        } label: {
            Text(labelText)
        }
        .buttonStyle(.bordered)
        .rotation3DEffect(.degrees(textRotation), axis: (x: 0, y: 1, z: 0))
        .rotation3DEffect(.degrees(boxRotation), axis: (x: 0, y: 1, z: 0))
        .accessibilityLabel("Time unit")
        .accessibilityValue(accessibilityValue)
        .accessibilityHint("Double-tap to switch between months and years.")
    }
    
    private var labelText: String {
        monthsInterval
            ? (timeInterval == 1 ? "month" : "months")
            : (timeInterval == 1 ? "year" : "years")
    }

    private var accessibilityValue: String {
        monthsInterval
            ?  timeInterval == 1 ? "month" : "months"
            :  timeInterval == 1 ? "year" : "years"
    }
    
    // Animates button toggle
    func flipButton() {
        let animationDuration = 0.3
        
        withAnimation(.linear(duration: animationDuration)) {
            if monthsInterval {
                boxRotation += 180
            } else {
                boxRotation -= 180
            }
        }
        
        withAnimation(.linear(duration: 0.001).delay(animationDuration / 2)) {
            if monthsInterval {
                textRotation += 180
            } else {
                textRotation -= 180
            }
        }
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
