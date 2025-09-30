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
    @State private var showingFuelEconomyInfo = false
    
    private var latestFillupFuelEconomy: Double {
        fillups.first?.fuelEconomy(settings: settings) ?? 0
    }
    
    private var previousFillupFuelEconomy: Double {
        fillups[1].fuelEconomy(settings: settings)
    }
    
    var body: some View {
        ZStack {
            Circle()
                .frame(width: 35)
                .foregroundStyle(Color(.tertiarySystemGroupedBackground))
            
            if latestFillupFuelEconomy != 0 {
                if latestFillupFuelEconomy > previousFillupFuelEconomy {
                    upArrow
                } else if latestFillupFuelEconomy < previousFillupFuelEconomy {
                    downArrow
                } else {
                    equalSign
                }
            } else {
                infoButton
            }
        }
        .foregroundStyle(settings.accentColor(for: .fillupsTheme))
        .font(.title2.bold())
        .onAppear { animateTrendArrow(shouldReset: false) }
        .mask {
            Circle()
                .frame(width: 35)
        }
        .onChange(of: Array(fillups)) {
            animateTrendArrow(shouldReset: true)
        }
    }
    
    // Up arrow Image
    private var upArrow: some View {
        Image(systemName: "chevron.up")
            .offset(y: animatingTrendArrow ? 0 : 35)
            .accessibilityLabel("Fuel economy is up since your last fill-up")
    }
    
    // Down arrow Image
    private var downArrow: some View {
        Image(systemName: "chevron.down")
            .offset(y: animatingTrendArrow ? 0 : -35)
            .accessibilityLabel("Fuel economy is down since your last fill-up")
    }
    
    // Equal sign Image
    private var equalSign: some View {
        Image(systemName: "equal")
            .accessibilityLabel("Fuel economy is the same as your last fill-up")
    }
    
    private var infoButton: some View {
        Button("Learn More", systemImage: "info") {
            showingFuelEconomyInfo = true
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.plain)
        .popover(isPresented: $showingFuelEconomyInfo) {
            Text("Fuel economy will be calculated after your next **Full Tank** fill-up.")
                .font(.subheadline)
                .foregroundStyle(Color.primary)
                .padding()
                .frame(width: 300)
                .presentationCompactAdaptation(.popover)
        }
    }
    
    // Animates trendArrow into view, with option to reset to it's original position off-screen (for animation after adding new fill-up)
    func animateTrendArrow(shouldReset: Bool) {
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
