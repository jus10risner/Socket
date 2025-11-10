//
//  InformationItemView.swift
//  SocketCD
//
//  Created by Justin Risner on 10/23/25.
//

import SwiftUI

struct InformationItemView: View {
    let title: String
    let description: String
    let imageName: String
    let accentColor: Color
    
    var body: some View {
        HStack(alignment: .center) {
            Image(systemName: imageName)
                .font(.title)
                .foregroundColor(accentColor)
                .symbolRenderingMode(.monochrome)
                .frame(width: 36, alignment: .center)
                .padding(.trailing, 8)
                .accessibility(hidden: true)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .accessibility(addTraits: .isHeader)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .layoutPriority(1)
        }
    }
}

#Preview {
    InformationItemView(title: "Maintain Vehicles", description: "Get reminders when routine maintenance services are due.", imageName: "book.and.wrench", accentColor: Color.indigo.mix(with: .cyan, by: 0.2))
}
