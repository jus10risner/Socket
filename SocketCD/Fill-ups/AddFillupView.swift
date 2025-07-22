//
//  AddFillupView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import SwiftUI

struct AddFillupView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var draftFillup = DraftFillup()
    let vehicle: Vehicle
    let quickFill: Bool
    
    init(vehicle: Vehicle, quickFill: Bool) {
        self.vehicle = vehicle
        self.quickFill = quickFill
        
        _draftFillup = StateObject(wrappedValue: DraftFillup())
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if quickFill == true {
                    Text(vehicle.name)
                        .padding(.horizontal, 10)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.secondary)
                }
                
                DraftFillupView(draftFillup: draftFillup, isEditView: false)
                    
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("New Fill-up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        vehicle.addNewFillup(draftFillup: draftFillup)
                        
                        dismiss()
                    }
                    .disabled(draftFillup.canBeSaved ? false : true)
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
            }
        }
    }
}

#Preview {
    AddFillupView(vehicle: Vehicle(context: DataController.preview.container.viewContext), quickFill: false)
        .environmentObject(AppSettings())
}
