//
//  TrendArrowView.swift
//  SocketCD
//
//  Created by Justin Risner on 7/1/25.
//

import SwiftUI

struct TrendArrowView: View {
    let settings = AppSettings.shared
    let fillups: FetchedResults<Fillup>
    
    @State private var animatingTrendArrow = false
    
    private var latestFillupFuelEconomy: Double {
        fillups.first?.fuelEconomy() ?? 0
    }
    
    private var previousFillupFuelEconomy: Double {
        fillups[1].fuelEconomy()
    }
    
    var body: some View {
        Circle()
            .frame(width: 35)
            .foregroundStyle(Color(.tertiarySystemGroupedBackground))
            .overlay {
                Group {
                    if latestFillupFuelEconomy != 0 {
                        if latestFillupFuelEconomy > previousFillupFuelEconomy {
                            indicatorSymbol(systemName: "chevron.up", accessibilityLabel: "Fuel economy is up since your last fill-up")
                                .offset(y: animatingTrendArrow ? 0 : 30)
                        } else if latestFillupFuelEconomy < previousFillupFuelEconomy {
                            indicatorSymbol(systemName: "chevron.down", accessibilityLabel: "Fuel economy is down since your last fill-up")
                                .offset(y: animatingTrendArrow ? 0 : -35)
                        } else {
                            indicatorSymbol(systemName: "equal", accessibilityLabel: "Fuel economy is the same as your last fill-up")
                        }
                    } else {
                        indicatorSymbol(systemName: "minus", accessibilityLabel: "Fuel economy is not available for this fill-up")
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
            .onChange(of: Array(fillups)) {
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
