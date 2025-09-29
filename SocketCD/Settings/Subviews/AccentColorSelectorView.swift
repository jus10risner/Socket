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
    
    let columns = [GridItem(.adaptive(minimum: 50), spacing: 10)]
    
    var body: some View {
        List {
            Section(footer: Text("Used for buttons and highlights throughout the app.")) {
                LazyVGrid(columns: columns, spacing: 10) {
                    
                    defaultAccentButton
                    
                    alternateAccentButtonsGrid
                }
                .buttonStyle(.plain)
                .font(.largeTitle.bold())
            }
        }
        .navigationTitle("Accent Color")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    
    // MARK: - Views
    
    // Button to select the default (multicolor) accent
    private var defaultAccentButton: some View {
        Button {
            settings.accentColor = nil
        } label: {
            Label("Default Accent", systemImage: settings.accentColor == nil ? "circle.fill" : "circle")
                .labelStyle(.iconOnly)
                .imageScale(.large)
                .foregroundStyle(LinearGradient(stops: [Gradient.Stop(color: .indigo, location: 0.1), Gradient.Stop(color: .blue, location: 0.4), Gradient.Stop(color: .orange, location: 0.7), Gradient.Stop(color: .mint, location: 1)], startPoint: .leading, endPoint: .trailing))
        }
    }
    
    // Buttons to select alternate accent color
    private var alternateAccentButtonsGrid: some View {
        ForEach(AccentColors.allCases, id: \.self) { color in
            Button {
                settings.accentColor = color
            } label: {
                Label(color.rawValue, systemImage: settings.accentColor == color ? "circle.fill" : "circle")
                    .labelStyle(.iconOnly)
                    .imageScale(.large)
                    .foregroundStyle(settings.colorValue(for: color))
            }
        }
    }
}

#Preview {
    AccentColorSelectorView()
        .environmentObject(AppSettings())
}
