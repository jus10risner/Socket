//
//  TrendArrowView.swift
//  SocketCD
//
//  Created by Justin Risner on 7/1/25.
//

import SwiftUI

struct TrendArrowView: View {
    let latestFuelEconomy: Double?
    let previousFuelEconomy: Double?
    let diameter: CGFloat = 35
    
    @State private var animatingTrendArrow = false
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 4)

            indicatorSymbol
                .foregroundStyle(.fillupsTheme)
                .scaledToFit()
                .bold()
                .padding(8)
                .mask {
                    Circle()
                        .frame(width: diameter, height: diameter)
                }
        }
        .frame(width: diameter, height: diameter)
        .onAppear { animateTrendArrow(shouldReset: false) }
        .onChange(of: latestFuelEconomy) {
            animateTrendArrow(shouldReset: true)
        }
    }
    
    private var indicatorSymbol: some View {
        Image(systemName: systemName)
            .resizable()
            .offset(y: arrowOffset)
            .accessibilityHidden(true)
    }

    private var systemName: String {
        guard let latestFuelEconomy, let previousFuelEconomy else { return "equal" }

        if latestFuelEconomy > previousFuelEconomy {
            return "chevron.up"
        } else if latestFuelEconomy < previousFuelEconomy {
            return "chevron.down"
        } else {
            return "equal"
        }
    }

    private var arrowOffset: CGFloat {
        guard !animatingTrendArrow else { return 0 }

        guard let latestFuelEconomy, let previousFuelEconomy else { return 0 }

        if latestFuelEconomy > previousFuelEconomy {
            return diameter
        } else if latestFuelEconomy < previousFuelEconomy {
            return -diameter
        } else {
            return 0
        }
    }
    
    // Animates trendArrow into view, with option to reset to it's original position off-screen (for animation after adding new fill-up)
    private func animateTrendArrow(shouldReset: Bool) {
        if shouldReset == true {
            withAnimation(nil) {
                animatingTrendArrow = false
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.bouncy) {
                animatingTrendArrow = true
            }
        }
    }
}
