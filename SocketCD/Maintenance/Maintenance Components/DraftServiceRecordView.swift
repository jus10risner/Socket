//
//  DraftServiceRecordView.swift
//  SocketCD
//
//  Created by Justin Risner on 4/5/24.
//

import SwiftUI

struct DraftServiceRecordView: View {
    @ObservedObject var draftServiceRecord: DraftServiceRecord
    let isEditView: Bool
    
    @FocusState var isInputActive: Bool
    @FocusState var fieldInFocus: Bool
    
    var body: some View {
        serviceRecordForm
    }
    
    
    // MARK: - Views
    
    private var serviceRecordForm: some View {
        Form {
            Section(footer: Text("*required")) {
                DatePicker("Service Date", selection: $draftServiceRecord.date, displayedComponents: .date)
                    .accentColor(Color.selectedColor(for: .maintenanceTheme))
                
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        if isEditView {
                            Text("Odometer")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                        }
                        
                        TextField("Odometer*", value: $draftServiceRecord.odometer, format: .number.decimalSeparator(strategy: .automatic))
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
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 5) {
                        if isEditView {
                            Text("Cost")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                        }
                        
                        TextField("Cost", value: $draftServiceRecord.cost, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .focused($isInputActive)
            
            Section("Note") {
                TextEditor(text: $draftServiceRecord.note)
                    .frame(minHeight: 50)
                    .focused($isInputActive)
            }
            
            Section(header: AddPhotoButton(photos: $draftServiceRecord.photos)) {
                EditablePhotoGridView(photos: $draftServiceRecord.photos)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

#Preview {
    DraftServiceRecordView(draftServiceRecord: DraftServiceRecord(), isEditView: true)
}
