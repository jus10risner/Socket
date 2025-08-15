//
//  AppIconSelectorView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/23/24.
//

import SwiftUI

struct AppIconSelectorView: View {
    @AppStorage("appIcon") var appIcon: AppIcon?
    
    var body: some View {
        List {
            iconOptions
                
            classicIcons
        }
        .pickerStyle(.inline)
        .navigationTitle("App Icon")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: appIcon) {
            UIApplication.shared.setAlternateIconName(appIcon?.rawValue)
        }
    }
    
    
    // MARK: - Views
    
    private var iconOptions: some View {
        Picker("2.0", selection: $appIcon) {
            iconLabel(title: "Primary", iconName: "Primary Icon")
                .tag(nil as AppIcon?)
            
            ForEach(AppIcon.allCases.filter { !$0.isClassic }, id: \.self) { icon in
                iconLabel(title: "\(icon.rawValue)", iconName: "\(icon.rawValue) Icon")
                    .tag(icon) // This connects the row to the selection binding
            }
        }
    }
    
    // Icons from the original version of Socket
    private var classicIcons: some View {
        Picker("1.0", selection: $appIcon) {
            ForEach(AppIcon.allCases.filter({ $0.isClassic }), id: \.self) { icon in
                iconLabel(title: "\(icon.rawValue)", iconName: "\(icon.rawValue) Icon")
                    .tag(icon)
            }
        }
    }
    
    private func iconLabel(title: String, iconName: String) -> some View {
        Label {
            Text(title)
                .padding(.leading, 5)
        } icon: {
            Image(iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.black.opacity(0.3), lineWidth: 0.5)
                )
        }
        .padding(.horizontal, 5)
    }
}

#Preview {
    AppIconSelectorView()
}
