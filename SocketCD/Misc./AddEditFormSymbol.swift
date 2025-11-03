//
//  AddEditFormSymbol.swift
//  SocketCD
//
//  Created by Justin Risner on 11/3/25.
//

import SwiftUI

struct AddEditFormSymbol: View {
    let symbolName: String
    let text: String
    let accentColor: Color
    
    var body: some View {
        Section {
            VStack {
                Image(systemName: symbolName)
                    .font(.title)
                    .foregroundStyle(.white)
                    .padding()
                    .background(accentColor.gradient, in: Circle())
                    .frame(maxWidth: .infinity)
                
                Text(text)
                    .font(.headline)
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }
}

#Preview {
    AddEditFormSymbol(symbolName: "wrench.adjustable.fill", text: "New Repair", accentColor: Color.repairsTheme)
}
