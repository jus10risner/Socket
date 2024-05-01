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
    
    let columnCount = 5
    let gridSpacing = 10.0
    let circleDiameter: CGFloat = 50
    
    var body: some View {
        List {
            Section(footer: Text("Choose a color to use on most buttons and elements throughout the app.")) {
                LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: gridSpacing), count: columnCount), spacing: gridSpacing) {
                    
                    defaultAccentButton
                    
                    alternateAccentButtonsGrid
                }
                .buttonStyle(.plain)
                .font(.title2.bold())
                .foregroundStyle(.white)
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
            ZStack {
                Circle()
                    .foregroundStyle(LinearGradient(stops: [Gradient.Stop(color: .indigo, location: 0.1), Gradient.Stop(color: .blue, location: 0.4), Gradient.Stop(color: .orange, location: 0.7), Gradient.Stop(color: .mint, location: 1)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: circleDiameter, height: circleDiameter)
                    .accessibilityLabel("Default Accent")
                
                if settings.accentColor == nil {
                    Image(systemName: "checkmark")
                }
            }
        }
    }
    
    // Buttons to select alternate accent color
    private var alternateAccentButtonsGrid: some View {
        ForEach(AccentColors.allCases, id: \.self) { color in
            Button {
                settings.accentColor = color
            } label: {
                ZStack {
                    Circle()
                        .foregroundStyle(settings.colorValue(for: color))
                        .frame(width: circleDiameter, height: circleDiameter)
                        .accessibilityLabel(color.rawValue)
                    
                    if settings.accentColor == color {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
    }
}

#Preview {
    AccentColorSelectorView()
        .environmentObject(AppSettings())
}
