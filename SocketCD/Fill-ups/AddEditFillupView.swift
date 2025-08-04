//
//  AddEditFillupView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import SwiftUI

struct AddEditFillupView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var settings: AppSettings
    @StateObject var draftFillup = DraftFillup()
    let vehicle: Vehicle?
    let fillup: Fillup?
    
    init(vehicle: Vehicle? = nil, fillup: Fillup? = nil) {
        self.vehicle = vehicle
        self.fillup = fillup
        
        if let fillup {
            _draftFillup = StateObject(wrappedValue: DraftFillup(fillup: fillup))
        } else {
            _draftFillup = StateObject(wrappedValue: DraftFillup())
        }
    }
    
    @State var showingFillTypeInfo = false
    
    @FocusState var isInputActive: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Fill-up Date", selection: $draftFillup.date, displayedComponents: .date)
                        .foregroundStyle(Color.secondary)
                    
                    LabeledInput(label: "Odometer") {
                        TextField("Required", value: $draftFillup.odometer, format: .number.decimalSeparator(strategy: .automatic))
                            .keyboardType(.numberPad)
                            .focused($isInputActive)
                    }
                    
                    LabeledInput(label: "\(settings.fuelEconomyUnit.volumeUnit)s of Fuel") {
                        TextField("Required", value: $draftFillup.volume, format: .number.decimalSeparator(strategy: .automatic))
                            .keyboardType(.decimalPad)
                    }
                    
                    LabeledInput(label: settings.fillupCostType == .perUnit ? "Price per \(settings.fuelEconomyUnit.volumeUnit)" : "Total Cost") {
                        TextField("Optional", value: $draftFillup.cost, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .keyboardType(.decimalPad)
                    }
                    
                    FillTypePicker(fillType: $draftFillup.fillType, showingFillTypeInfo: $showingFillTypeInfo)
                }
                
                Section("Note") {
//                    TextEditor(text: $draftFillup.note)
                    TextField("Optional", text: $draftFillup.note, axis: .vertical)
                }
                
                Section(header: AddPhotoButton(photos: $draftFillup.photos)) {
                    EditablePhotoGridView(photos: $draftFillup.photos)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .sheet(isPresented: $showingFillTypeInfo) { FillTypeInfoView() }
            .navigationTitle(fillup != nil ? "Edit Fill-up" : "New Fill-up")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if fillup == nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                        isInputActive = true
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if let fillup {
                            fillup.updateAndSave(draftFillup: draftFillup)
                        } else if let vehicle {
                            vehicle.addNewFillup(draftFillup: draftFillup)
                        }
                        
                        dismiss()
                    }
                    .disabled(draftFillup.canBeSaved ? false : true)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
            }
        }
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    
    AddEditFillupView(vehicle: Vehicle(context: context), fillup: Fillup(context: context))
        .environmentObject(AppSettings())
}
