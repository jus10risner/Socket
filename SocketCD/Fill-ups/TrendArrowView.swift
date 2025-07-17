//
//  TrendArrowView.swift
//  SocketCD
//
//  Created by Justin Risner on 7/1/25.
//

import SwiftUI

struct TrendArrowView: View {
    @EnvironmentObject var settings: AppSettings
    let fillups: FetchedResults<Fillup>
    
    @State private var animatingTrendArrow = false
    
    private var latestFillupFuelEconomy: Double {
        fillups.first?.fuelEconomy ?? 0
    }
    
    private var previousFillupFuelEconomy: Double {
        fillups[1].fuelEconomy
    }
    
    var body: some View {
        ZStack {
            Circle()
                .frame(width: 40, height: 40)
                .foregroundStyle(Color(.tertiarySystemGroupedBackground))
            
            if latestFillupFuelEconomy > previousFillupFuelEconomy {
                upArrow
            } else if latestFillupFuelEconomy < previousFillupFuelEconomy {
                downArrow
            } else {
                equalSign
            }
        }
        .foregroundStyle(Color.selectedColor(for: .fillupsTheme))
        .font(.title.bold())
        .animation(.bouncy, value: animatingTrendArrow)
        .onAppear { animateTrendArrow(shouldReset: false) }
        .mask {
            Circle()
                .frame(width: 40, height: 40)
        }
        .onChange(of: Array(fillups)) {
            animateTrendArrow(shouldReset: true)
        }
    }
    
    // Up arrow Image
    private var upArrow: some View {
        Image(systemName: "chevron.up")
//            .foregroundStyle(settings.fuelEconomyUnit == .L100km ? .red : .green)
            .offset(y: animatingTrendArrow ? 0 : 40)
            .accessibilityLabel("Fuel economy is up since your last fill-up")
    }
    
    // Down arrow Image
    private var downArrow: some View {
        Image(systemName: "chevron.down")
//            .foregroundStyle(settings.fuelEconomyUnit == .L100km ? .green : .red)
            .offset(y: animatingTrendArrow ? 0 : -40)
            .accessibilityLabel("Fuel economy is down since your last fill-up")
    }
    
    // Equal sign Image
    private var equalSign: some View {
        Image(systemName: "equal")
//            .foregroundStyle(Color.selectedColor(for: .fillupsTheme))
            .accessibilityLabel("Fuel economy is the same as your last fill-up")
    }
    
    // Animates trendArrow into view, with option to reset to it's original position off-screen (for animation after adding new fill-up)
    func animateTrendArrow(shouldReset: Bool) {
        if shouldReset == true {
            animatingTrendArrow = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            animatingTrendArrow = true
        }
    }
}

//#Preview {
//    TrendArrowView()
//}
