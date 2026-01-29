//
//  OnboardingTips.swift
//  SocketCD
//
//  Created by Justin Risner on 11/17/25.
//

import TipKit

struct DashboardTip: Tip {
    var title: Text {
        Text("Welcome to the dashboard!")
    }
    
    var message: Text? {
        Text("Quickly add or update info with the circular quick action button on each card, or tap the card itself to go to that section of the app.")
    }
    
    var image: Image? {
        Image(systemName: "rectangle.3.group.fill")
    }
}

struct LogServiceTip: Tip {
    var title: Text {
        Text("Logging Maintenance")
    }
    
    var message: Text? {
        Text("""
            Tap to set up a maintenance service.

            After setup, use the **plus** button to create service logs.
            """)
        .accessibilityLabel("Set up a maintenance service.")
    }
    
    var image: Image? {
        Image(systemName: "hand.tap.fill")
    }
}
