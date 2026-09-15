//
//  DashboardCard.swift
//  SocketCD
//
//  Created by Justin Risner on 9/11/26.
//

import SwiftUI

struct DashboardCard<Visual: View, Detail: View>: View {
    let title: String
    let color: Color
    let quickActionTitle: String
    let accessibilityValue: String
    let accessibilityHint: String
    var disableButton: Bool? = nil
    let action: () -> Void
    let quickAction: () -> Void
    @ViewBuilder let visual: Visual
    @ViewBuilder let detail: Detail
    
    @State private var feedbackTrigger = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Button(action: action) {
                VStack(alignment: .leading) {
                    HStack {
                        Text(title)
                            .foregroundStyle(.secondary)
                            .font(.headline)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundStyle(.tertiary)
                    }
                    
                    Spacer()
                    
                    HStack(alignment: .bottom) {
                        statusRow
                        
                        // Reserves space beneath the overlaid quick action button
                        Spacer()
                            .frame(width: 44)
                    }
                }
                .frame(minHeight: 80)
                .padding()
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle.adaptive)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title)
            .accessibilityValue(accessibilityValue)
            .accessibilityHint(accessibilityHint)
            
            Button {
                feedbackTrigger.toggle()
                quickAction()
            } label: {
                Label(quickActionTitle, systemImage: "plus")
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.circle)
            .tint(color)
            .disabled(disableButton ?? false)
            .sensoryFeedback(.impact(weight: .light), trigger: feedbackTrigger)
            .padding()
        }
    }
    
    private var statusRow: some View {
        HStack {
            visual

            detail
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    DashboardCard(title: "Maintenance", color: .green, quickActionTitle: "Log Service", accessibilityValue: "Due soon", accessibilityHint: "Tap to log", action: {}, quickAction: {}) {
        Image(systemName: "book.and.wrench")
            .foregroundStyle(.green)
            .frame(width: 35, height: 35)
            .background(.green.opacity(0.14), in: Circle())
            .accessibilityHidden(true)
    } detail: {
        VStack(alignment: .leading) {
            Text("Oil Change")
                .font(.title3.bold())

            Text("Due in 500 mi or 14 days.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    .frame(height: 80)
}
