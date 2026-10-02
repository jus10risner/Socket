//
//  CardSymbolView.swift
//  SocketCD
//
//  Created by Justin Risner on 10/1/26.
//

import SwiftUI

struct CardSymbolView: View {
    let symbolName: String
    let diameter: CGFloat = 35

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 4)

            Image(systemName: symbolName)
        }
        .frame(width: diameter, height: diameter)
        .accessibilityHidden(true)
    }
}

#Preview {
    CardSymbolView(symbolName: "fuelpump.fill")
        .foregroundStyle(.mint)
}
