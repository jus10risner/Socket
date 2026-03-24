//
//  LabeledInput.swift
//  SocketCD
//
//  Created by Justin Risner on 8/1/25.
//

import SwiftUI

// Standardizes the look of input form fields
struct LabeledInput<Content: View>: View {
    var label: String
    let content: () -> Content
    
    var body: some View {
        LabeledContent(label) {
            content()
                .foregroundStyle(Color.primary)
                .multilineTextAlignment(.trailing)
        }
        .foregroundStyle(Color.secondary)
    }
}
