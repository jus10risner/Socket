//
//  TrendArrowView.swift
//  SocketCD
//
//  Created by Justin Risner on 7/1/25.
//

import SwiftUI

struct TrendArrowView: View {
    let fuelEconomies: [Double]
    
    @State private var animatingTrendArrow = false
    
    private var validFuelEconomies: [Double] {
        fuelEconomies.lazy
            .filter { $0 > 0 }
            .prefix(2)
            .map { $0 }
    }
    
    private var latestFillupFuelEconomy: Double? {
        validFuelEconomies.first
    }
    
    private var previousFillupFuelEconomy: Double? {
        validFuelEconomies.dropFirst().first
    }
    
    var body: some View {
        Circle()
            .frame(width: 35)
            .foregroundStyle(Color(.fillupsTheme).opacity(0.14))
            .overlay {
                Group {
                    if let latestFillupFuelEconomy, let previousFillupFuelEconomy {
                        if latestFillupFuelEconomy > previousFillupFuelEconomy {
                            indicatorSymbol(systemName: "chevron.up", accessibilityLabel: "Fuel economy is up since your previous valid fill-up")
                                .offset(y: animatingTrendArrow ? 0 : 35)
                        } else if latestFillupFuelEconomy < previousFillupFuelEconomy {
                            indicatorSymbol(systemName: "chevron.down", accessibilityLabel: "Fuel economy is down since your previous valid fill-up")
                                .offset(y: animatingTrendArrow ? 0 : -35)
                        } else {
                            indicatorSymbol(systemName: "equal", accessibilityLabel: "Fuel economy is the same as your previous valid fill-up")
                        }
                    } else {
                        indicatorSymbol(systemName: "equal", accessibilityLabel: "No previous fuel economy value to compare")
                    }
                }
                .foregroundStyle(Color(.fillupsTheme))
                .scaledToFit()
                .bold()
                .padding(8)
            }
            .onAppear { animateTrendArrow(shouldReset: false) }
            .mask {
                Circle()
                    .frame(width: 35)
            }
            .onChange(of: fuelEconomies) {
                animateTrendArrow(shouldReset: true)
            }
    }
    
    // Symbol to display inside the circle, along with an accessibility label to explain what the symbol means
    private func indicatorSymbol(systemName: String, accessibilityLabel: String) -> some View {
        Image(systemName: systemName)
            .resizable()
            .accessibilityLabel(accessibilityLabel)
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
