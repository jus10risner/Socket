//
//  EditFillupView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import SwiftUI

struct EditFillupView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var draftFillup = DraftFillup()
//    @ObservedObject var vehicle: Vehicle
    var fillup: Fillup
    
    @State private var showingFillTypeInfo = false
    
    init(fillup: Fillup) {
        self.fillup = fillup
        
        _draftFillup = StateObject(wrappedValue: DraftFillup(fillup: fillup))
    }
    
    var body: some View {
        NavigationStack {
            DraftFillupView(draftFillup: draftFillup, isEditView: true, showingFillTypeInfo: $showingFillTypeInfo)
                .navigationTitle("Edit Fill-up")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear { fillup.populateCorrectCost(draftFillup: draftFillup) }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel", role: .cancel) { dismiss() }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            fillup.updateAndSave(draftFillup: draftFillup)
                            
                            dismiss()
                        }
                        .disabled(draftFillup.canBeSaved ? false : true)
                    }
                }
        }
        .overlay(
            Group {
                if showingFillTypeInfo {
                    FillTypeInfoView(showingFillTypeInfo: $showingFillTypeInfo)
                }
            }
        )
    }
}

#Preview {
    EditFillupView(fillup: Fillup(context: DataController.preview.container.viewContext))
}
