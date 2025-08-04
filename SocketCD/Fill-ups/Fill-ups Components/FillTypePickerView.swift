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
        HStack(alignment: .center, spacing: 3) {
            Group {
                Text("Fill Type")
                    .foregroundStyle(Color.secondary)
                
                Button {
                    showingFillTypeInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(settings.accentColor(for: .fillupsTheme))
                        .accessibilityLabel("Learn More")
                }
            }
            
            Spacer()
            
            Menu {
                Picker("Select Fill Type", selection: $fillType) {
                    ForEach(FillType.allCases, id: \.self) { fillupType in
                        Text(fillupType.rawValue)
                    }
                }
                .labelsHidden()
            } label: {
                HStack(spacing: 2) {
                    Text(fillType.rawValue)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .accessibilityHidden(true)
                }
//                .foregroundStyle(settings.accentColor(for: .fillupsTheme))
            }
            .transaction { transaction in
                transaction.animation = nil
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FillTypePicker(fillType: .constant(.fullTank), showingFillTypeInfo: .constant(true))
        .environmentObject(AppSettings())
}
