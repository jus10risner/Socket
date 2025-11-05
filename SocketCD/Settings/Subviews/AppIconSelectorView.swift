//
//  AppIconSelectorView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/23/24.
//

import SwiftUI

struct AppIconSelectorView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appIcon") var appIcon: AppIcon?
    
    var body: some View {
        List {
            Picker("Icons", selection: $appIcon) {
                iconLabel(title: "Socket Purple", iconName: "Primary Icon")
                    .tag(nil as AppIcon?)
                
                ForEach(AppIcon.allCases, id: \.self) { icon in
                    iconLabel(title: "\(icon.rawValue)", iconName: "\(icon.rawValue) Icon")
                        .tag(icon) // This connects the row to the selection binding
                }
            }
            .labelsHidden()
        }
        .pickerStyle(.inline)
        .navigationTitle("App Icon")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: appIcon) {
            UIApplication.shared.setAlternateIconName(appIcon?.rawValue)
        }
    }
    
    
    // MARK: - Views
    
    private func iconLabel(title: String, iconName: String) -> some View {
        Label {
            Text(title)
                .padding(.leading, 5)
        } icon: {
            Image(iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary, lineWidth: 0.2)
                )
                .environment(\.colorScheme,
                    {
                        if #available(iOS 18, *) {
                            return colorScheme
                        } else {
                            // iOS 17: force light mode only
                            return .light
                        }
                    }()
                )
        }
        .padding(8)
    }
}

#Preview {
    AppIconSelectorView()
}
