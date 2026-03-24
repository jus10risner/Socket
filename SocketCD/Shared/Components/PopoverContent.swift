//
//  PopoverContent.swift
//  SocketCD
//
//  Created by Justin Risner on 11/21/25.
//

import SwiftUI

struct PopoverContent: View {
    let text: String
    
    var body: some View {
        ScrollView {
            Text(text)
                .font(.subheadline)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding()
                .presentationCompactAdaptation(.popover)
        }
        .frame(minHeight: 100, maxHeight: 400)
        .frame(minWidth: 300, idealWidth: 350, maxWidth: 400)
    }
}

#Preview {
    PopoverContent(text: "Test popover content")
}
