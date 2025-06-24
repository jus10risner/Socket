//
//  View+helper.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import SwiftUI

extension View {
    
    @ViewBuilder
    func colorSchemeBackground(colorScheme: ColorScheme) -> some View {
      if colorScheme == .dark {
        foregroundStyle(Color(.darkGray).opacity(0.3))
      } else {
        foregroundStyle(Color(.secondarySystemGroupedBackground))
      }
    }
    
    // Custom modifier that uses the appropriate modal style, based on iOS version
    @ViewBuilder
    func appropriateImagePickerModal(isPresented: Binding<Bool>, image: Binding<UIImage?>, onDismiss: (() -> ())?) -> some View {
        if #available(iOS 16, *) {
            self.sheet(isPresented: isPresented, onDismiss: onDismiss) {
                ImagePicker(image: image).ignoresSafeArea()
            }
        } else {
            self.sheet(isPresented: isPresented, onDismiss: onDismiss) {
                ImagePicker(image: image)
            }
        }
    }
}
