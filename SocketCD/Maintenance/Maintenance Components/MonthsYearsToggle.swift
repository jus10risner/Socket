//
//  MonthsYearsToggle.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import SwiftUI

struct MonthsYearsToggle: View {
    @EnvironmentObject var settings: AppSettings
    @Binding var monthsInterval: Bool
    let timeInterval: Int?
    
    @State private var boxRotation = 0.001 // Using 0.0 here causes error: "ignoring singular matrix..." on iOS 16+
    @State private var textRotation = 0.0 // ""
    
    var body: some View {
//        monthsYearsToggleButton
        alternateToggleButton
//        buttonToggle
    }
    
    
    // MARK: - Views
    
    // Button that toggles between months and years
//    private var monthsYearsToggleButton: some View {
//        ZStack {
//            if monthsInterval == true {
//                Text(timeInterval == 1 ? "month" : "months")
//            } else {
//                Text(timeInterval == 1 ? "year" : "years")
//            }
//        }
//        .rotation3DEffect(.degrees(textRotation), axis: (x: 0, y: 1, z: 0))
//        .padding(4)
//        .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(settings.accentColor(for: .maintenanceTheme)))
//        .foregroundStyle(settings.accentColor(for: .maintenanceTheme))
//        .onTapGesture {
//            flipButton()
//        }
//        .rotation3DEffect(.degrees(boxRotation), axis: (x: 0, y: 1, z: 0))
//        .accessibilityHint("Tap to toggle between months and years")
//    }
    
    private var buttonToggle: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                monthsInterval.toggle()
            }
        } label: {
            Group {
                if monthsInterval == true {
                    Text(timeInterval == 1 ? "month" : "months")
                } else {
                    Text(timeInterval == 1 ? "year" : "years")
                }
            }
//            Text(monthsInterval ? "Months" : "Years")
//                .font(.headline)
//                .padding(.horizontal, 16)
//                .padding(.vertical, 8)
//                .background(
//                    Capsule()
//                        .fill(monthsInterval ? Color.blue : Color.green)
//                        .shadow(radius: 2)
//                )
//                .foregroundColor(.white)
//                .transition(.scale.combined(with: .opacity))
        }
        .buttonStyle(.bordered)
    }
    
    private var alternateToggleButton: some View {
        Button {
            flipButton()
        } label: {
            if monthsInterval == true {
                Text(timeInterval == 1 ? "month" : "months")
            } else {
                Text(timeInterval == 1 ? "year" : "years")
            }
        }
        .buttonStyle(.bordered)
        .rotation3DEffect(.degrees(textRotation), axis: (x: 0, y: 1, z: 0))
        .rotation3DEffect(.degrees(boxRotation), axis: (x: 0, y: 1, z: 0))
    }
    
    
    // MARK: - Methods
    
    // Animates button toggle
    func flipButton() {
        let animationDuration = 0.3
        
        withAnimation(.linear(duration: animationDuration)) {
            if monthsInterval {
                boxRotation += 180
            } else {
                boxRotation -= 180
            }
        }
        
        withAnimation(.linear(duration: 0.001).delay(animationDuration / 2)) {
            if monthsInterval {
                textRotation += 180
            } else {
                textRotation -= 180
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration / 2) {
                monthsInterval.toggle()
            }
        }
    }
}

#Preview {
    MonthsYearsToggle(monthsInterval: .constant(true), timeInterval: 2)
        .environmentObject(AppSettings())
}
