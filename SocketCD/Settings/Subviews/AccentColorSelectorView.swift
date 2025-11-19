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
                    defaultAccentButton
                    
                    alternateAccentButtons
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
    
    
    // MARK: - Views
    
    // Button to select the default (multicolor) accent
    private var defaultAccentButton: some View {
        Button {
            settings.accentColor = nil
        } label: {
            Label {
                Text("Socket Purple")
            } icon: {
                Image(systemName: "circle.fill")
                    .font(.title)
                    .foregroundStyle(Color.accent)
            }
            .padding(5)
        }
        .tag(nil as AccentColors?)
    }
    
    // Buttons to select alternate accent color
    private var alternateAccentButtons: some View {
        ForEach(AccentColors.allCases, id: \.self) { color in
            Button {
                settings.accentColor = color
            } label: {
                Label {
                    Text(color.rawValue.capitalized)
                } icon: {
                    Image(systemName: "circle.fill")
                        .font(.title)
                        .foregroundStyle(settings.colorValue(for: color))
                }
                .padding(5)
            }
            .tag(color as AccentColors?)
        }
    }
}

#Preview {
    AccentColorSelectorView()
        .environmentObject(AppSettings())
}
