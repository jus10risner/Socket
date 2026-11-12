//
//  AddEditCustomInfoView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import SwiftUI

struct AddEditCustomInfoView: View {
    // MARK: - Environment
    @Environment(\.dismiss) var dismiss
    
    // MARK: - State
    @StateObject var draftCustomInfo = DraftCustomInfo()
    @FocusState private var focusedField: Field?
    @State private var didSetInitialFocus = false
    @State private var showingDuplicateLabelError = false
    @State private var showingDeleteAlert = false
    
    // MARK: - Input
    private let vehicle: Vehicle?
    private let customInfo: CustomInfo?
    private let onDelete: (() -> Void)?
    let settings = AppSettingsStore.shared
    
    // MARK: - Init
    init(vehicle: Vehicle? = nil, customInfo: CustomInfo? = nil, onDelete: (() -> Void)? = nil) {
        self.vehicle = vehicle
        self.customInfo = customInfo
        self.onDelete = onDelete
        
        _draftCustomInfo = StateObject(wrappedValue: DraftCustomInfo(customInfo: customInfo))
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                FormHeaderView(symbolName: AppSection.customInfo.symbol(filled: true), primaryText: customInfo != nil ? "Edit Custom Info" : "New Custom Info", accentColor: AppSection.customInfo.color)
                
                Section {
                    LabeledInput(label: "Name") {
                        TextField("e.g. Tire Size", text: $draftCustomInfo.label)
                            .focused($focusedField, equals: .name)
                            .selectAllOnFocus()
                    }
                    
                    LabeledInput(label: "Information") {
                        TextField("e.g. 225/45R17", text: $draftCustomInfo.detail)
                            .focused($focusedField, equals: .information)
                            .selectAllOnFocus()
                    }
                }
                
                FormFooterView (
                    note: $draftCustomInfo.note,
                    photos: $draftCustomInfo.photos,
                    documents: $draftCustomInfo.documents,
                    deleteButtonTitle: "Delete Info",
                    focusedField: $focusedField,
                    noteField: .note,
                    onDelete: onDelete != nil ? { showingDeleteAlert = true } : nil
                )
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(
                edge: .bottom,
                content: {
                    if focusedField != nil {
                        KeyboardToolbar(
                            canMovePrevious: focusedField != .name,
                            canMoveNext: focusedField != .note,
                            onPrevious: focusPreviousField,
                            onNext: focusNextField,
                            onDone: { focusedField = nil }
                        )
                }
            })
            .task {
                guard customInfo == nil, !didSetInitialFocus else { return }
                didSetInitialFocus = true
                
                await Task.yield()
                guard !Task.isCancelled else { return }
                
                focusedField = .name
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(customInfo != nil ? "Done" : "Add", systemImage: "checkmark") {
                        focusedField = nil
                        if let customInfo {
                            customInfo.updateAndSave(draftCustomInfo: draftCustomInfo)
                        } else if let vehicle {
                            if vehicle.sortedCustomInfoArray.contains(where: { $0.label == draftCustomInfo.label }) {
                                showingDuplicateLabelError = true
                            } else {
                                vehicle.addNewInfo(draftCustomInfo: draftCustomInfo)
                            }
                        }
                        
                        dismiss()
                    }
                    .labelStyle(.adaptive)
                    .disabled(draftCustomInfo.canBeSaved ? false : true)
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
            .tint(AppSection.customInfo.color)
            .alert("Delete Vehicle Info", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    focusedField = nil
                    if let customInfo {
                        DataController.shared.delete(customInfo)
                    }
                    
                    dismiss()
                    onDelete?()
                }
                Button("Cancel", role: .cancel) { focusedField = nil }
            } message: {
                Text("Permanently delete this info? This cannot be undone.")
            }
            .alert("That label has already been used.", isPresented: $showingDuplicateLabelError) {
                Button("OK", role: .cancel) { focusedField = nil }
            } message: {
                Text("Please choose a different label.")
            }
        }
        .tint(nil)
    }
    
    private enum Field: Hashable {
        case name, information, note
    }
    
    private func focusNextField() {
        switch focusedField {
        case .name:
            focusedField = .information
        case .information:
            focusedField = .note
        default:
            break
        }
    }
    
    private func focusPreviousField() {
        switch focusedField {
        case .information:
            focusedField = .name
        case .note:
            focusedField = .information
        default:
            break
        }
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345
    
    let customInfo = CustomInfo(context: context)
    customInfo.label = "License Plate"
    customInfo.detail = "ABC 123"
    
    return AddEditCustomInfoView(vehicle: vehicle, customInfo: customInfo)
}
