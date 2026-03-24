//
//  AdaptiveLabelStyle.swift
//  SocketCD
//
//  Created by Justin Risner on 9/25/25.
//

import SwiftUI

struct AdaptiveLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 26, *) {
            configuration.icon
        } else {
            configuration.title
        }
    }
}

extension LabelStyle where Self == AdaptiveLabelStyle {
    static var adaptive: AdaptiveLabelStyle { AdaptiveLabelStyle() }
}
