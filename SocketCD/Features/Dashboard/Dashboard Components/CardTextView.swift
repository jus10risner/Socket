//
//  CardTextView.swift
//  SocketCD
//
//  Created by Justin Risner on 9/14/26.
//

import SwiftUI

struct CardTextView: View {
    let headline: String
    let subheadline: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(headline)
                .font(.headline)
            
            Text(subheadline)
                .font(.footnote.bold())
                .foregroundStyle(Color.secondary)
        }
    }
}

#Preview {
    CardTextView(headline: "No Fill-ups Logged", subheadline: "Add your first fill-up when you’re ready")
}
