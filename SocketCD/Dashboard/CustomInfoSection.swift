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
                ForEach(vehicle.sortedCustomInfoArray, id: \.id) { customInfo in
                    NavigationLink {
                        CustomInfoDetailView(customInfo: customInfo)
                            .tint(settings.accentColor(for: .appTheme))
                    } label: {
                        HStack {
                            LabeledContent(customInfo.label) {
                                if !customInfo.detail.isEmpty {
                                    Text(customInfo.detail)
                                        .foregroundStyle(Color.secondary)
                                    
                                } else if customInfo.photos?.count != 0 {
                                    Image(systemName: "photo")
                                        .foregroundStyle(Color.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.footnote)
                                .foregroundStyle(Color.secondary)
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle.adaptive)
                    }
                    .buttonStyle(.plain)
                }
                
                VStack(spacing: 20) {
                    if vehicle.sortedCustomInfoArray.isEmpty {
                        Text("Add things like your vehicle's VIN or photos of important documents here, for easy reference.")
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                    }
                    
                    Button {
                        activeSheet = .addCustomInfo
                    } label: {
                        Label("Add Info", systemImage: "plus")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .tint(settings.accentColor(for: .appTheme))
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle.adaptive)
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
