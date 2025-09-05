//
//  FillTypePickerView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import SwiftUI

struct FillTypePicker: View {
    @EnvironmentObject var settings: AppSettings
    @Binding var fillType: FillType
    @Binding var showingFillTypeInfo: Bool
    
    var body: some View {
        LabeledContent {
            Picker("Select Fill Type", selection: $fillType) {
                ForEach(FillType.allCases, id: \.self) { fillupType in
                    Text(fillupType.rawValue)
                }
            }
            .labelsHidden()
        } label: {
            HStack {
                Text("Fill Type")
                    .foregroundStyle(Color.secondary)
                
                Button("Learn More", systemImage: "info.circle") {
                    showingFillTypeInfo = true
                }
                .labelStyle(.iconOnly)
                .foregroundStyle(settings.accentColor(for: .fillupsTheme))
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FillTypePicker(fillType: .constant(.fullTank), showingFillTypeInfo: .constant(true))
        .environmentObject(AppSettings())
}
