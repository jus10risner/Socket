//
//  MonthsYearsToggle.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import SwiftUI

struct MonthsYearsToggle: View {
    @Binding var monthsInterval: Bool
    let timeInterval: Int?
    
    @State private var boxRotation = 0.001 // Using 0.0 here causes error: "ignoring singular matrix..." on iOS 16+
    @State private var textRotation = 0.0 // ""
    
    var body: some View {
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
}
