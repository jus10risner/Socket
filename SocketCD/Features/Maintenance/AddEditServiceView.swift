//
//  AddEditServiceView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import SwiftUI

struct AddEditServiceView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    private let settings = AppSettingsStore.shared
    
    // MARK: - State
    @StateObject private var draftService: DraftService
    @StateObject private var previousServiceLog = DraftServiceLog()
    @StateObject private var customStartLog: DraftServiceLog
    @FocusState private var isInputActive: Bool
    @State private var showingDuplicateNameError = false
    @State private var odometerWarning: OdometerWarning?
    @State private var trackingStart: TrackingStart?
    @State private var showingDeleteAlert = false
    @ScaledMetric private var selectionIconWidth = 24
    
    private enum TrackingStart {
        case previousService, custom, later
    }
    
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
        _customStartLog = StateObject(wrappedValue: {
            let draft = DraftServiceLog()
            draft.odometer = vehicle?.odometer ?? service?.vehicle?.odometer
            return draft
        }())
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
                    ViewThatFits(in: .horizontal) {
                        HStack {
                            distanceField

                            timeField
                        }
                        
                        VStack(alignment: .leading) {
                            distanceField

                            timeField
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .padding(.vertical, UIDevice.current.systemVersion.hasPrefix("18.") ? 5 : 0)
                } header: {
                    VStack(alignment: .leading) {
                        Text("Service Interval")
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                        
                        Text("""
                            Enter distance, time, or both. 
                            Service is due when the first is reached.
                            """)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .headerProminence(.increased)
                
                if service == nil {
                    Section {
                        trackingOption(.previousService, title: "Last completion", subtitle: "Enter when you last completed this service to calculate when it is due next.")
                    } header: {
                        VStack(alignment: .leading) {
                            Text("Select a starting point")
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)
                            
                            Text("Choose when and how to begin tracking this service.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .headerProminence(.increased)

                    Section {
                        trackingOption(.custom, title: "Custom date and odometer", subtitle: "Enter your own values to calculate when this service is due next. Great for new vehicles or unknown history.")
                    }
                    .listSectionSpacing(5)

                    Section {
                        trackingOption(.later, title: "First service log", subtitle: "Calculate when this service is due next only after you log it for the first time.")
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
                    .disabled(!canSave)
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
    
    private var distanceField: some View {
        HStack {
            TextField("5,000", text: optionalIntFieldBinding($draftService.distanceInterval))
                .fixedSize()
                .accessibilityLabel("Distance interval")
                .accessibilityHint("Enter the number of " + distanceUnit.rawValue)
            
            Text("\(distanceUnit.abbreviated) or")
                .accessibilityHidden(true)
        }
    }
    
    private var timeField: some View {
        HStack {
            TextField("6", text: optionalIntFieldBinding($draftService.timeInterval))
                .fixedSize()
                .accessibilityLabel("Time interval")
                .accessibilityHint("Enter the number of months or years")
            
            MonthsYearsToggle(
                monthsInterval: $draftService.monthsInterval,
                timeInterval: draftService.timeInterval ?? 0
            )
        }
    }

    @ViewBuilder
    private func trackingOption(_ option: TrackingStart, title: LocalizedStringKey, subtitle: LocalizedStringKey) -> some View {
        Button {
            isInputActive = false
            withAnimation {
                trackingStart = option
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: trackingStart == option ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(trackingStart == option ? AppSection.maintenance.color : Color.secondary)
                    .imageScale(.large)
                    .frame(width: selectionIconWidth)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(trackingStart == option ? .isSelected : [])
        .padding(.vertical, 4)

        if trackingStart == option && option != .later {
            let draft = option == .custom ? $customStartLog : $previousServiceLog

            DatePicker("Date", selection: draft.date, displayedComponents: .date)
                .padding(.leading, selectionIconWidth + 12)

            LabeledInput(label: "Odometer") {
                TextField("Required", value: draft.odometer, format: .number.decimalSeparator(strategy: .automatic))
                    .keyboardType(.numberPad)
                    .accessibilityLabel("Odometer")
            }
            .padding(.leading, selectionIconWidth + 12)
        }
    }

    private var canSave: Bool {
        guard draftService.canBeSaved else { return false }
        guard service == nil else { return true }
        guard let trackingStart else { return false }
        return trackingStart == .later || draftServiceLog.odometer != nil
    }

    private var draftServiceLog: DraftServiceLog {
        trackingStart == .custom ? customStartLog : previousServiceLog
    }

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

        if trackingStart != .later, let entered = draftServiceLog.odometer,
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
        } else if let vehicle {
            guard let trackingStart,
                  trackingStart == .later || draftServiceLog.odometer != nil else { return }

            vehicle.addNewService(
                draftService: draftService,
                initialRecord: trackingStart == .later ? nil : draftServiceLog,
                isBaseLine: trackingStart == .custom
            )
        }

        dismiss()
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
    let timeInterval: Int
    
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
        .accessibilityValue(labelText)
        .accessibilityHint("Double-tap to switch between months and years.")
    }
    
    private var labelText: String {
        monthsInterval
            ? (timeInterval == 1 ? "month" : "months")
            : (timeInterval == 1 ? "year" : "years")
    }

    // Animates button toggle
    private func flipButton() {
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
