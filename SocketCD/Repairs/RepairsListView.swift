//
//  RepairsListView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import SwiftUI

struct RepairsListView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) var dismiss
    @ObservedObject var vehicle: Vehicle
    
    @FetchRequest var repairs: FetchedResults<Repair>
    
    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        self._repairs = FetchRequest(
            entity: Repair.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Repair.date_, ascending: false)],
            predicate: NSPredicate(format: "vehicle == %@", vehicle)
        )
    }
    
    @State private var showingAddRepair = false
    @State private var showingContent = false
    
    var body: some View {
        repairsList
    }
    
    
    // MARK: - Views
    
    var repairsList: some View {
        AppropriateNavigationType {
            List {
                ForEach(repairs, id: \.id) { repair in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundStyle(Color(.secondarySystemGroupedBackground))
                        
                        NavigationLink {
                            RepairDetailView(vehicle: vehicle, repair: repair)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(repair.name)
                                        .font(.headline)
                                    
                                    Text("\(repair.odometer.formatted()) \(settings.shortenedDistanceUnit)")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.secondary)
                                }
                                
                                Spacer()
                                
                                Text(repair.date.formatted(date: .numeric, time: .omitted))
                                    .font(.subheadline)
                                    .foregroundStyle(Color.secondary)
                            }
                            .padding(.vertical, 5)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color(.systemGroupedBackground))
                    .listRowInsets(EdgeInsets(top: 2.5, leading: 20, bottom: 2.5, trailing: 20))
                }
            }
            .listStyle(.plain)
            .background(Color(.systemGroupedBackground))
            .overlay {
                if vehicle.sortedRepairsArray.isEmpty {
                    RepairsStartView(showingAddRepair: $showingAddRepair)
                }
            }
            .navigationTitle("Repairs")
//            .onChange(of: vehicle.odometer) { _ in
//                print("Odometer changed (repairs)")
//                vehicle.determineIfNotificationDue()
//            }
            .sheet(isPresented: $showingAddRepair) {
                AddRepairView(vehicle: vehicle)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack {
                        Spacer()
                        Text(vehicle.name)
                            .font(.headline)
                            .lineLimit(1)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color.secondary)
                            .accessibilityLabel("Back to all vehicles")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddRepair = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .accessibilityLabel("Add New Repair")
                    }
                    // iOS 16 workaround, where button could't be clicked again after sheet was dismissed - iOS 15 and 17 work fine without this
                    .id(UUID())
                }
            }
        }
    }
}

#Preview {
    RepairsListView(vehicle: Vehicle(context: DataController.preview.container.viewContext))
        .environmentObject(AppSettings())
}
