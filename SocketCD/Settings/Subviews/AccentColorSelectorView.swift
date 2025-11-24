//
//  AccentColorSelectorView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import CoreData
import SwiftUI

struct AccentColorSelectorView: View {
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        List {
            Section {
                Picker("Accent Color", selection: $settings.accentColor) {
                    pickerLabel(text: "Socket Purple", color: Color.accent)
                        .tag(nil as AccentColors?)
                    
                    ForEach(AccentColors.allCases, id: \.self) { color in
                        pickerLabel(text: color.rawValue.capitalized, color: color.value)
                            .tag(color as AccentColors?)
                    }
                    
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } footer: {
                Text("Used for buttons and highlights throughout the app.")
            }
        }
        .buttonStyle(.plain)
        .navigationTitle("Accent Color")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func pickerLabel(text: String, color: Color) -> some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: "circle.fill")
                .font(.title)
                .foregroundStyle(color)
        }
        .padding(5)
    }
}

#Preview {
    AccentColorSelectorView()
        .environmentObject(AppSettings())
}
