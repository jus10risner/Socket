//
//  DraftRepairView.swift
//  SocketCD
//
//  Created by Justin Risner on 4/4/24.
//

import SwiftUI

struct DraftRepairView: View {
    @ObservedObject var draftRepair: DraftRepair
    let isEditView: Bool
    
    @FocusState var isInputActive: Bool
    @FocusState var fieldInFocus: Bool
    
    var body: some View {
        repairForm
    }
    
    
    // MARK: - Views
    
    private var repairForm: some View {
        Form {
            Section(footer: Text("*required")) {
                DatePicker("Repair Date", selection: $draftRepair.date, displayedComponents: .date)
                    .accentColor(Color.selectedColor(for: .repairsTheme))
                    
                TextField("Repair Name*", text: $draftRepair.name)
                    .textInputAutocapitalization(.words)
                    .focused($fieldInFocus)
                    .onAppear {
                        if isEditView == false {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                                fieldInFocus = true
                            }
                        }
                    }
                
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        if isEditView {
                            Text("Odometer")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                                .accessibilityHidden(true)
                        }
                        
                        TextField("Odometer*", value: $draftRepair.odometer, format: .number.decimalSeparator(strategy: .automatic))
                            .keyboardType(.numberPad)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 5) {
                        if isEditView {
                            Text("Cost")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                                .accessibilityHidden(true)
                        }
                        
                        TextField("Cost", value: $draftRepair.cost, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .focused($isInputActive)
            
            Section("Note") {
                TextEditor(text: $draftRepair.note)
                    .frame(minHeight: 50)
                    .focused($isInputActive)
            }
            
            Section(header: AddPhotoButton(photos: $draftRepair.photos)) {
                EditablePhotoGridView(photos: $draftRepair.photos)
            }
        }
        .modifier(SwipeToDismissKeyboard())
    }
}

#Preview {
    DraftRepairView(draftRepair: DraftRepair(), isEditView: false)
}
