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
    
    @State private var showingFillTypeInfo = false
    
    init(vehicle: Vehicle, quickFill: Bool) {
        self.vehicle = vehicle
        self.quickFill = quickFill
        
        _draftFillup = StateObject(wrappedValue: DraftFillup())
    }
    
    var body: some View {
        AppropriateNavigationType {
            VStack(spacing: 0) {
                if quickFill == true {
                    Text(vehicle.name)
                        .padding(.horizontal, 10)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.secondary)
                }
                
                DraftFillupView(draftFillup: draftFillup, vehicle: vehicle, isEditView: false, showingFillTypeInfo: $showingFillTypeInfo)
                    
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
    AddFillupView(vehicle: Vehicle(context: DataController.preview.container.viewContext), quickFill: false)
        .environmentObject(AppSettings())
}
