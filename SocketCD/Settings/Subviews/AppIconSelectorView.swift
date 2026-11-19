//
//  AppIconSelectorView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/23/24.
//

import SwiftUI

struct AppIconSelectorView: View {
    @AppStorage("appIcon") private var appIcon: AppIcon?

    @State private var isChangingIcon = false
    @State private var showingIconError = false

    private let iconSize: CGFloat = 60

    private var iconShape: RoundedRectangle {
        // Approximate the Home Screen's continuous corners for each OS generation.
        let radius: CGFloat
        if #available(iOS 26, *) {
            radius = iconSize * 0.26
        } else {
            radius = iconSize * 0.224
        }
        return RoundedRectangle(cornerRadius: radius, style: .continuous)
    }

    var body: some View {
        NavigationStack {
            List {
                Group {
                    iconButton(title: "Socket Purple", imageName: "Primary Icon", icon: nil)
                    
                    ForEach(AppIcon.allCases, id: \.rawValue) { icon in
                        iconButton(
                            title: LocalizedStringKey(icon.rawValue),
                            imageName: "\(icon.rawValue) Icon",
                            icon: icon
                        )
                    }
                }
                .disabled(isChangingIcon)
            }
            .navigationTitle("App Icon")
            .alert("Could Not Change App Icon", isPresented: $showingIconError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please try again.")
            }
        }
    }

    // MARK: - Views

    private func iconButton(title: LocalizedStringKey, imageName: String, icon: AppIcon?) -> some View {
        let isSelected = appIcon == icon

        return Button {
            changeIcon(to: icon)
        } label: {
            HStack(spacing: 16) {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: iconSize, height: iconSize)
                    .clipShape(iconShape)
                    .overlay {
                        iconShape
                            .strokeBorder(.primary.opacity(0.25), lineWidth: 1)
                    }
                    .accessibilityHidden(true)

                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                Image(systemName: "checkmark")
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentColor)
                    .opacity(isSelected ? 1 : 0)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Actions

    private func changeIcon(to icon: AppIcon?) {
        guard !isChangingIcon, appIcon != icon else { return }
        guard UIApplication.shared.supportsAlternateIcons else {
            showingIconError = true
            return
        }

        let previousIcon = appIcon
        appIcon = icon
        isChangingIcon = true

        Task { @MainActor in
            defer { isChangingIcon = false }

            do {
                try await UIApplication.shared.setAlternateIconName(icon?.rawValue)
            } catch {
                appIcon = previousIcon
                showingIconError = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        List {
            Section("App Icon") {
                AppIconSelectorView()
            }
        }
        .navigationTitle("Appearance")
    }
}
