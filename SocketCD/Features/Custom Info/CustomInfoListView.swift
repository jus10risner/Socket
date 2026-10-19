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
            sortDescriptors: [
                NSSortDescriptor(keyPath: \CustomInfo.label_, ascending: true)
            ],
            predicate: NSPredicate(format: "vehicle == %@", vehicle)
        )
    }

    @State private var showingAddCustomInfo = false

    var body: some View {
        List {
            ForEach(customInfo, id: \.id) { customInfo in
                NavigationLink {
                    CustomInfoDetailView(customInfo: customInfo)
                } label: {
                    CustomInfoListRow(customInfo: customInfo)
                }
                .buttonStyle(.plain)
            }
        }
        .sectionNavigationTitle(AppSection.customInfo.title, vehicleName: vehicle.name)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .overlay {
            if customInfo.isEmpty {
                ContentUnavailableView {
                    Label("No Saved Info", systemImage: AppSection.customInfo.symbol())
                } description: {
                    Text("Keep useful details here, such as tire size or insurance documents.")
                }
            }
        }
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
            }
        }
    }
}

private struct CustomInfoListRow: View {
    @ObservedObject var customInfo: CustomInfo

    var body: some View {
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
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345

    return CustomInfoListView(vehicle: vehicle)
}
