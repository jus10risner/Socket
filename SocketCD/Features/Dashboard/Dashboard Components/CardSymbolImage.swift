//
//  CardSymbolImage.swift
//  SocketCD
//
//  Created by Justin Risner on 9/14/26.
//

import SwiftUI

struct CardSymbolImage: View {
    let symbolName: String
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color, lineWidth: 4)

            Image(systemName: symbolName)
                .foregroundStyle(color)
        }
        .frame(width: 35, height: 35)
        .accessibilityHidden(true)
    }
}

#Preview {
    CardSymbolImage(symbolName: "fuelpump.fill", color: .mint)
}
