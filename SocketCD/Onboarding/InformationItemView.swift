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
                .frame(width: 30)
                .padding()
                .accessibility(hidden: true)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .accessibility(addTraits: .isHeader)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top)
    }
}

#Preview {
    InformationItemView(title: "Maintain Vehicles", description: "Get reminders when routine maintenance services are due.", imageName: "book.and.wrench.fill", accentColor: Color.indigo.mix(with: .cyan, by: 0.2))
}
