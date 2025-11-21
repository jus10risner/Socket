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
        Text(text)
            .fixedSize(horizontal: false, vertical: true)
            .font(.subheadline)
            .padding()
            .padding(.vertical, 40)
            .frame(maxWidth: 350)
            .presentationCompactAdaptation(.popover)
    }
}

#Preview {
    PopoverContent(text: "Test popover content")
}
