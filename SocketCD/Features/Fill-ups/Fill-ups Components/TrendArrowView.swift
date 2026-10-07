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
    let diameter: CGFloat = 50
    
    @State private var animatingTrendArrow = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(.fillupsTheme).gradient)

            Image(systemName: "fuelpump.fill")
                .imageScale(.large)
                .offset(
                    x: animatingTrendArrow ? fuelPumpOffset.width : 0,
                    y: animatingTrendArrow ? fuelPumpOffset.height : 0
                )

            indicatorSymbol
        }
        .foregroundStyle(.white)
        .frame(width: diameter, height: diameter)
        .clipShape(Circle())
        .onAppear { introduceTrendArrow() }
        .onChange(of: latestFuelEconomy) {
            animateTrendArrow(shouldReset: true)
        }
    }
    
    private var indicatorSymbol: some View {
        Image(systemName: systemName)
            .font(.title.bold())
            .offset(
                x: animatingTrendArrow ? 0 : -fuelPumpOffset.width,
                y: animatingTrendArrow ? 0 : -fuelPumpOffset.height
            )
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

    private var fuelPumpOffset: CGSize {
        guard let latestFuelEconomy, let previousFuelEconomy else { return .zero }

        if latestFuelEconomy > previousFuelEconomy {
            return CGSize(width: 0, height: -diameter)
        } else if latestFuelEconomy < previousFuelEconomy {
            return CGSize(width: 0, height: diameter)
        } else {
            return CGSize(width: diameter, height: 0)
        }
    }

    private func introduceTrendArrow() {
        guard !animatingTrendArrow else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.bouncy) {
                animatingTrendArrow = true
            }
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
