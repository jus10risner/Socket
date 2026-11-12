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
    @FocusState private var focusedField: Field?
    @State private var didSetInitialFocus = false
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
            ScrollViewReader { proxy in
                Form {
                    FormHeaderView(symbolName: AppSection.maintenance.symbol(), primaryText: service != nil ? "Edit Service" : "New Service", accentColor: AppSection.maintenance.color)
                    
                    Section {
                        TextField("Service Name (e.g. Oil Change)", text: $draftService.name)
                            .textInputAutocapitalization(.words)
                            .focused($focusedField, equals: .name)
                            .selectAllOnFocus()
                            .id(Field.name)
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
                        .id(Field.distance)
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
                            .focused($focusedField, equals: .note)
                            .selectAllOnFocus()
                            .id(Field.note)
                    }
                    
                    if onDelete != nil {
                        Button("Delete Service", role: .destructive) {
                            focusedField = nil
                            showingDeleteAlert = true
                        }
                    }
                    
                }
                .scrollDismissesKeyboard(.interactively)
                .navigationBarTitleDisplayMode(.inline)
                .safeAreaInset(
                    edge: .bottom,
                    content: {
                        if focusedField != nil {
                            KeyboardToolbar(
                                canMovePrevious: focusedField != .name,
                                canMoveNext: focusedField != .note,
                                onPrevious: { focusPreviousField(using: proxy) },
                                onNext: { focusNextField(using: proxy) },
                                onDone: { focusedField = nil }
                            )
                    }
                })
                .task {
                    guard service == nil, !didSetInitialFocus else { return }
                    didSetInitialFocus = true

                    await Task.yield()
                    guard !Task.isCancelled else { return }

                    focusedField = .name
                }
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(service != nil ? "Done" : "Add", systemImage: "checkmark") {
                            focusedField = nil
                            saveService()
                        }
                        .labelStyle(.adaptive)
                        .disabled(!canSave)
                    }
                    
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", systemImage: "xmark", role: .cancel) {
                            focusedField = nil
                            dismiss()
                        }
                            .labelStyle(.adaptive)
                            .adaptiveTint()
                    }
                }
                .tint(AppSection.maintenance.color)
                .alert("Delete Service", isPresented: $showingDeleteAlert) {
                    Button("Delete", role: .destructive) {
                        focusedField = nil
                        if let service {
                            DataController.shared.delete(service)
                        }
                        
                        dismiss()
                        onDelete?()
                    }
                    
                    Button("Cancel", role: .cancel) { focusedField = nil }
                } message: {
                    Text("Permanently delete this service and all of its records? This cannot be undone.")
                }
                .alert("This vehicle already has a service with that name", isPresented: $showingDuplicateNameError) {
                    Button("OK", role: .cancel) { focusedField = nil }
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
        }
        .tint(nil)
    }
    
    // MARK: - Methods
    
    private enum Field: Hashable {
        case name, distance, time, odometer, note
    }
    
    private var showsOdometerField: Bool {
        service == nil && trackingStart != nil && trackingStart != .later
    }

    private func focusPreviousField(using proxy: ScrollViewProxy) {
        switch focusedField {
        case .distance:
            focus(.name, using: proxy)
        case .time:
            focus(.distance, using: proxy)
        case .odometer:
            focus(.time, using: proxy)
        case .note:
            focus(showsOdometerField ? .odometer : .time, using: proxy)
        default:
            break
        }
    }
    
    private func focusNextField(using proxy: ScrollViewProxy) {
        switch focusedField {
        case .name:
            focus(.distance, using: proxy)
        case .distance:
            focus(.time, using: proxy)
        case .time:
            focus(showsOdometerField ? .odometer : .note, using: proxy)
        case .odometer:
            focus(.note, using: proxy)
        default:
            break
        }
    }
    
    private func focus(_ field: Field, using proxy: ScrollViewProxy) {
        let currentField = focusedField
        // Distance and Time share one form row.
        let row = field == .time ? Field.distance : field

        withAnimation(.default, completionCriteria: .removed) {
            proxy.scrollTo(row)
        } completion: {
            // Don't restore focus if the user dismissed the keyboard or chose another field.
            guard focusedField == currentField else { return }
            focusedField = field
        }
    }

    private var distanceField: some View {
        HStack {
            TextField("5,000", value: optionalNumberBinding($draftService.distanceInterval), format: .number)
                .fixedSize()
                .focused($focusedField, equals: .distance)
                .selectAllOnFocus()
                .accessibilityLabel("Distance interval")
                .accessibilityHint("Enter the number of " + distanceUnit.rawValue)
            
            Text("\(distanceUnit.abbreviated) or")
                .accessibilityHidden(true)
        }
    }
    
    private var timeField: some View {
        HStack {
            TextField("6", value: optionalNumberBinding($draftService.timeInterval), format: .number)
                .fixedSize()
                .focused($focusedField, equals: .time)
                .selectAllOnFocus()
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
            focusedField = nil
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
                    .focused($focusedField, equals: .odometer)
                    .selectAllOnFocus()
                    .accessibilityLabel("Odometer")
            }
            .padding(.leading, selectionIconWidth + 12)
            .id(Field.odometer)
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
    
    // Treats zero as an empty value while allowing TextField to format numbers.
    private func optionalNumberBinding(_ value: Binding<Int?>) -> Binding<Int?> {
        Binding(
            get: {
                value.wrappedValue == 0 ? nil : value.wrappedValue
            },
            set: { newValue in
                value.wrappedValue = newValue == 0 ? nil : newValue
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
