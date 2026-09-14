//
//  ToolbarTitleView.swift
//  SocketCD
//
//  Created by Justin Risner on 9/14/26.
//

import SwiftUI

struct ToolbarTitleView: View {
    let sectionTitle: String
    let vehicleName: String
    
    var body: some View {
        VStack(spacing: 0) {
            Text(sectionTitle)
                .font(.headline)
            
            Text(vehicleName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
    }
}

#Preview {
    ToolbarTitleView(sectionTitle: "Fill-ups", vehicleName: "My Car")
}
