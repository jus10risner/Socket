//
//  FillTypeInfoView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import SwiftUI

struct FillTypeInfoView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Full Tank")
                            .font(.headline)
                        
                        Text("Select this fill type if you have filled your fuel tank completely. To track fuel economy accurately, it is important to always try to use Full Tank fill-ups.")
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Partial Fill")
                            .font(.headline)
                        
                        Text("Select this fill type if fuel was added, but the fuel tank is not completely full. Fuel economy will not be calculated for this fill-up, but will resume after your next Full Tank fill-up.")
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Missed Fill-up (Full Tank)")
                            .font(.headline)
                        
                        Text("Select this fill type if you forgot to add one or more recent fill-ups to Socket. Fuel economy calculation will resume after your next Full Tank fill-up.")
                        
                        Text("**Note:** Only select this fill type if your fuel tank is full. If not, please wait until your next Full Tank fill-up to begin adding fill-ups to Socket again.")
                            .font(.footnote)
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
            .font(.subheadline)
            .navigationTitle("Fill Types")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    Button("Done", systemImage: "xmark") {
                        dismiss()
                    }
                    .labelStyle(.adaptive)
                    .adaptiveTint()
                }
            }
        }
        .onAppear() {
            // Dismisses keyboard
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

#Preview {
    FillTypeInfoView()
}
