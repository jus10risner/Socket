//
//  FillTypePickerView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import SwiftUI

struct FillTypePicker: View {
    @Binding var fillType: FillType
    @Binding var showingFillTypeInfo: Bool
    
    var body: some View {
        LabeledInput(label: "Fill Type") {
            Picker("Select a Fill Type", selection: $fillType) {
                ForEach(FillType.allCases, id: \.self) { fillupType in
                    Text(fillupType.rawValue)
                }
            }
            .labelsHidden()
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FillTypePicker(fillType: .constant(.fullTank), showingFillTypeInfo: .constant(true))
}
