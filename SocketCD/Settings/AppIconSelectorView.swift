//
//  AppIconSelectorView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/23/24.
//

import SwiftUI

struct AppIconSelectorView: View {
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        List {
            Section(footer: Text("Choose an icon to represent Socket on this device.")) {
                primaryIconButton
                
                alternateIconButtonsList
            }
            .onChange(of: settings.appIcon) { _ in
                UIApplication.shared.setAlternateIconName(settings.appIcon?.rawValue)
            }
        }
        .navigationTitle("App Icon")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    
    // MARK: - Views
    
    // Button for the primary purple Socket Icon
    private var primaryIconButton: some View {
        Button {
            settings.appIcon = nil
        } label: {
            HStack {
                Image("Primary Icon")
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibilityHidden(true)
                
                Text("Primary")
                    .foregroundStyle(Color.primary)
                
                Spacer()
                
                if settings.appIcon == nil {
                    Image(systemName: "checkmark")
                }
            }
        }
    }
    
    // Buttons for alternat icons
    private var alternateIconButtonsList: some View {
        ForEach(AvailableAppIcons.allCases, id: \.self) { icon in
            Button {
                settings.appIcon = icon
            } label: {
                HStack {
                    Image("\(icon.rawValue) Icon")
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.black.opacity(0.3), lineWidth: 0.5)
                                .foregroundStyle(Color.clear)
                        )
                        .accessibilityHidden(true)
                    
                    Text(icon.rawValue)
                        .foregroundStyle(Color.primary)
                    
                    Spacer()

                    if settings.appIcon == icon {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
    }
}

#Preview {
    AppIconSelectorView()
        .environmentObject(AppSettings())
}
