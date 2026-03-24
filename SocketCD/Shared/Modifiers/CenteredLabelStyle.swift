//
//  CenteredLabelStyle.swift
//  SocketCD
//
//  Created by Justin Risner on 7/15/25.
//

import SwiftUI

// Centers the icon horizontally with multiline text labels
struct CenteredLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center) {
            configuration.icon
            configuration.title
        }
    }
}
