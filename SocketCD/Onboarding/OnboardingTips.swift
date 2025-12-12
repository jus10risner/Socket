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
            Tap the **book** button to set up a new maintenance service.
            
            Tap the **plus** button each time you complete a service to create a service log.
            """)
        .accessibilityLabel("Tap the Set Up New Service button to define a new maintenance service. Tap the Log Service button each time you complete an existing service to create a service log.")
    }
    
    var image: Image? {
        Image(systemName: "hand.tap.fill")
    }
}

struct ServiceLogTip: Tip {
    var title: Text {
        Text("Choose Services")
    }
    
    var message: Text? {
        Text("Select one or more services to log. All services you select will share the information entered here.")
    }
    
    var image: Image? {
        Image(systemName: "checkmark.circle.fill")
    }
}
