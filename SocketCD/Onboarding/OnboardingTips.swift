//
//  OnboardingTips.swift
//  SocketCD
//
//  Created by Justin Risner on 11/17/25.
//

import TipKit

struct DashboardTip: Tip {
    var title: Text {
        Text("Welcome to the Dashboard")
    }
    
    var message: Text? {
        Text("Tap the action button on a card to add or edit info, or tap the card itself to view details.")
    }
    
    var image: Image? {
        Image(systemName: "rectangle.3.group.fill")
    }
}

struct MaintenanceListTip: Tip {
    var title: Text {
        Text("Log Maintenance")
    }
    
    var message: Text? {
//        Text("""
//            Tap the **book** button to set up a new maintenance service.
//            
//            Tap the **plus** button each time you complete an existing service to log it.
//            """)
        Text("Tap to set up a new maintenance service.")
    }
    
    var image: Image? {
        Image(systemName: "checklist.unchecked")
    }
}

struct LogServiceTip: Tip {
    var title: Text {
        Text("Log Maintenance")
    }
    
    var message: Text? {
//        Text("Tap the **plus** button each time you complete a service to log it.")
        Text("""
            Tap the **book** button to set up a new maintenance service.
            
            Tap the **plus** button each time you complete an existing service to log it.
            """)
    }
    
    var image: Image? {
        Image(systemName: "plus.circle.fill")
    }
}

struct ServiceLogTip: Tip {
    var title: Text {
        Text("Log Multiple Services")
    }
    
    var message: Text? {
        Text("Select one or more services to log. They will share all notes, photos, and details you enter.")
    }
    
    var image: Image? {
        Image(systemName: "circle.grid.2x2.topleft.checkmark.filled")
    }
}
