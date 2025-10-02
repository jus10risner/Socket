//
//  CustomInfoSection.swift
//  SocketCD
//
//  Created by Justin Risner on 10/1/25.
//

import SwiftUI

struct CustomInfoSection: View {
    @EnvironmentObject var settings: AppSettings
    @ObservedObject var vehicle: Vehicle
    let columns: [GridItem]
    
    @Binding var activeSheet: ActiveSheet?
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Custom Info")
                .font(.headline)
                .padding(.leading)
            
            LazyVGrid(columns: columns, spacing: 5) {
                if !vehicle.sortedCustomInfoArray.isEmpty {
                    ForEach(vehicle.sortedCustomInfoArray, id: \.id) { customInfo in
                        NavigationLink {
                            CustomInfoDetailView(customInfo: customInfo)
                        } label: {
                            HStack {
                                Text(customInfo.label)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.footnote)
                                    .foregroundStyle(Color.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle.adaptive)
                    }
                } else {
                    Text("Add things like your vehicle's VIN or photos of important documents here, for easy reference.")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle.adaptive)
                }
                
                Button("Add Info", systemImage: "plus") {
                    activeSheet = .addCustomInfo
                }
                .foregroundStyle(settings.accentColor(for: .appTheme))
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    RoundedRectangle.adaptive
                        .strokeBorder(Color.secondary, style: StrokeStyle(lineWidth: 0.5, dash: [5, 3]))
                }
            }
        }
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345
    
    return CustomInfoSection(vehicle: vehicle, columns: [], activeSheet: .constant(nil))
        .environmentObject(AppSettings())
}
