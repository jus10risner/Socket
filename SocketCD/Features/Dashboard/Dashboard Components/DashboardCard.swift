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
        VStack(spacing: 0) {
            Button(action: action) {
                VStack(alignment: .leading, spacing: 20) {
                    DashboardCardHeader(
                        title: title
                    )

                    cardContent
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding()
            .accessibilityLabel(title)
            .accessibilityValue(accessibilityValue)
            .accessibilityHint(accessibilityHint)
            
            Divider()
                .padding(.horizontal)

            Button {
                feedbackTrigger.toggle()
                quickAction()
            } label: {
                Label(quickActionTitle, systemImage: "plus")
                    .labelStyle(.iconOnly)
                    .imageScale(.large)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(color)
            .disabled(disableButton ?? false)
            .sensoryFeedback(.impact(weight: .light), trigger: feedbackTrigger)
            .padding()
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle.adaptive)
    }
    
    private var cardContent: some View {
        HStack {
            visual
                .foregroundStyle(color)
            
            detail
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct DashboardCardHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
            
            Spacer()

            Image(systemName: "chevron.forward")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
    }
}

#Preview {
    List {
        DashboardCard(
            title: "Maintenance",
            color: .green,
            quickActionTitle: "Log Service",
            accessibilityValue: "Due soon",
            accessibilityHint: "Opens maintenance services",
            action: {},
            quickAction: {}
        ) {
            CardSymbolView(symbolName: "book.and.wrench.fill")
        } detail: {
            CardTextView(
                headline: "Oil Change",
                subheadline: "Due in 500 mi or 14 days."
            )
        }
        .listRowInsets(EdgeInsets())
    }
}
