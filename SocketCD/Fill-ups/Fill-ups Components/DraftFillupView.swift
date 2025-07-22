//
//  DraftFillupView.swift
//  SocketCD
//
//  Created by Justin Risner on 4/5/24.
//

import SwiftUI

struct DraftFillupView: View {
    @EnvironmentObject var settings: AppSettings
    @ObservedObject var draftFillup: DraftFillup
//    let vehicle: Vehicle
    let isEditView: Bool
    @State var showingFillTypeInfo = false
    
    @FocusState var isInputActive: Bool
    @FocusState var fieldInFocus: Bool
    
    var body: some View {
        fillupForm
    }
    
    
    // MARK: - Views
    
    private var fillupForm: some View {
        Form {
            Section(footer: Text("*required")) {
                DatePicker("Fill-up Date", selection: $draftFillup.date, displayedComponents: .date)
                    .accentColor(settings.accentColor(for: .fillupsTheme))
                
                VStack(alignment: .leading, spacing: 5) {
                    if isEditView {
                        Text("Odometer")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                            .accessibilityHidden(true)
                    }
                    
                    TextField("Odometer*", value: $draftFillup.odometer, format: .number.decimalSeparator(strategy: .automatic))
                        .keyboardType(.numberPad)
                        .focused($fieldInFocus)
                        .onAppear {
                            if isEditView == false {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                                    fieldInFocus = true
                                }
                            }
                        }
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        if isEditView {
                            Text("\(settings.fuelEconomyUnit.volumeUnit)s of Fuel")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                                .accessibilityHidden(true)
                        }
                        
                        TextField("\(settings.fuelEconomyUnit.volumeUnit)s of Fuel*", value: $draftFillup.volume, format: .number.decimalSeparator(strategy: .automatic))
                            .keyboardType(.decimalPad)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 5) {
                        if isEditView {
                            Text(settings.fillupCostType == .perUnit ? "Price per \(settings.fuelEconomyUnit.volumeUnit.lowercased())" : "Total Cost")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                                .accessibilityHidden(true)
                        }
                        
                        TextField(settings.fillupCostType == .perUnit ? "Price per \(settings.fuelEconomyUnit.volumeUnit.lowercased())" : "Total Cost", value: $draftFillup.cost, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .keyboardType(.decimalPad)
                    }
                    .padding(.leading, 10)
                }
                
                FillTypePicker(fillType: $draftFillup.fillType, showingFillTypeInfo: $showingFillTypeInfo)
            }
            .focused($isInputActive)
            
            Section("Note") {
                TextEditor(text: $draftFillup.note)
                    .frame(minHeight: 50)
                    .focused($isInputActive)
            }
            
            Section(header: AddPhotoButton(photos: $draftFillup.photos)) {
                EditablePhotoGridView(photos: $draftFillup.photos)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .sheet(isPresented: $showingFillTypeInfo, content: { FillTypeInfoView() })
    }
}

#Preview {
    DraftFillupView(draftFillup: DraftFillup(), isEditView: true)
        .environmentObject(AppSettings())
}
