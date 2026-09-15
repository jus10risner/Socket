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
    
    @State private var animatingTrendArrow = false
    
    var body: some View {
        Circle()
            .frame(width: 35)
            .foregroundStyle(Color(.fillupsTheme).opacity(0.14))
            .overlay {
                indicatorSymbol
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
            return 35
        } else if latestFuelEconomy < previousFuelEconomy {
            return -35
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
