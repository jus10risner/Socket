//
//  CardSymbolView.swift
//  SocketCD
//
//  Created by Justin Risner on 10/1/26.
//

import SwiftUI

struct CardSymbolView: View {
    let symbolName: String
    let diameter: CGFloat = 50

    var body: some View {
        ZStack {
            Circle()

            Image(systemName: symbolName)
                .imageScale(.large)
                .foregroundStyle(.white)
        }
        .frame(width: diameter, height: diameter)
        .dynamicTypeSize(.medium)
        .accessibilityHidden(true)
    }
}

#Preview {
    CardSymbolView(symbolName: "fuelpump.fill")
        .foregroundStyle(.mint)
}
