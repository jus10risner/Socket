//
//  CustomInfoListView.swift
//  SocketCD
//
//  Created by Justin Risner on 9/11/26.
//

import CoreData
import SwiftUI

struct CustomInfoListView: View {
    @ObservedObject var vehicle: Vehicle
    let settings = AppSettingsStore.shared
    
    @FetchRequest var customInfo: FetchedResults<CustomInfo>
    
    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        self._customInfo = FetchRequest(
            entity: CustomInfo.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \CustomInfo.label_, ascending: false)],
            predicate: NSPredicate(format: "vehicle == %@", vehicle)
        )
    }
    
    @State private var showingAddCustomInfo = false
    
    var body: some View {
        ZStack {
            if customInfo.isEmpty {
                EmptyCustomInfoView()
            } else {
                List {
                    ForEach(vehicle.sortedCustomInfoArray, id: \.id) { customInfo in
                        NavigationLink {
                            CustomInfoDetailView(customInfo: customInfo)
                        } label: {
                            LabeledContent(customInfo.label) {
                                if !customInfo.detail.isEmpty {
                                    Text(customInfo.detail)
                                        .foregroundStyle(Color.secondary)
                                    
                                } else if customInfo.photos?.count != 0 {
                                    Image(systemName: "photo")
                                        .foregroundStyle(Color.secondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .vehicleNavigationTitle("Custom Info", vehicleName: vehicle.name)
        .sheet(isPresented: $showingAddCustomInfo) {
            AddEditCustomInfoView(vehicle: vehicle)
        }
        .toolbar {
            AdaptiveToolbarButton {
                Button("Add Info", systemImage: "plus") {
                    showingAddCustomInfo = true
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
//                .tint(Color.accentColor)
            }
        }
    }
}

#Preview {let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345
    
    return CustomInfoListView(vehicle: vehicle)
}
