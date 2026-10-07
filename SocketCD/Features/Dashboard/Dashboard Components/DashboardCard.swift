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

    private let quickActionSize: CGFloat = 44
    private let minimumContentHeight: CGFloat = 125

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: action) {
                cardContent
            }
            .buttonStyle(.plain)
            .padding()
            .accessibilityLabel(title)
            .accessibilityValue(accessibilityValue)
            .accessibilityHint(accessibilityHint)

            Button {
                feedbackTrigger.toggle()
                quickAction()
            } label: {
                Label(quickActionTitle, systemImage: "plus")
                    .labelStyle(.iconOnly)
                    .imageScale(.large)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .tint(color)
            .frame(width: quickActionSize, height: quickActionSize, alignment: .topTrailing)
            .contentShape(Rectangle())
            .dynamicTypeSize(.medium)
            .disabled(disableButton ?? false)
            .sensoryFeedback(.impact(weight: .light), trigger: feedbackTrigger)
            .padding()
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle.adaptive)
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                visual
                    .foregroundStyle(color.gradient)

                Spacer(minLength: 0)

                Color.clear
                    .frame(width: quickActionSize, height: quickActionSize)
                    .accessibilityHidden(true)
            }

            Spacer(minLength: 10)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption2)
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                
                detail
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(minHeight: minimumContentHeight, alignment: .top)
        .contentShape(Rectangle())
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
