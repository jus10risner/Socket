//
//  EmptyCustomInfoView.swift
//  SocketCD
//
//  Created by Justin Risner on 9/11/26.
//

import SwiftUI

struct EmptyCustomInfoView: View {
    var body: some View {
        ContentUnavailableView {
            Label {
                Text("Add what you need")
            } icon: {
                Image(systemName: "bookmark")
                    .foregroundStyle(Color.accentColor)
            }
        } description: {
            Text("Save anything you may want to reference later, such as a VIN or photo of your insurance paperwork.")
                .font(.body)
        }
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    EmptyCustomInfoView()
}
