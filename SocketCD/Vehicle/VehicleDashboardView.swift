//
//  VehicleDashboardView.swift
//  SocketCD
//
//  Created by Justin Risner on 7/10/25.
//

import SwiftUI

struct VehicleDashboardView: View {
//    @Binding var selectedVehicle: Vehicle
    let selectedVehicle: Vehicle
    
    let columns: [GridItem] = {
        [GridItem(.adaptive(minimum: 300), spacing: 5)]
    }()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 5) {
                    Text("Overview")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    LazyVGrid(columns: columns, spacing: 5) {
                        largeDashboardCard(label: Label("Next Service Due", systemImage: "book.and.wrench.fill"), color: .blue, primaryText: "Oil & Filter Change", secondaryText: "2,481 mi or 72 days")
                        
                        
                        HStack(spacing: 5) {
                            smallDashboardCard(label: Label("Odometer", systemImage: "road.lanes"), color: .indigo, primaryText: "12,345", secondaryText: "mi")
                            
                            smallDashboardCard(label: Label("Latest Fill-up", systemImage: "fuelpump.fill"), color: .mint, primaryText: "27.3", secondaryText: "mpg")
                        }
                    }
                }
                .padding(.top, 15)
                .padding(.horizontal)
                
                VStack(spacing: 5) {
                    Text("Records")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    LazyVGrid(columns: columns, spacing: 5) {
                        NavigationLink {
                            MaintenanceListView(vehicle: selectedVehicle)
                        } label: {
                            categoryCardLabel(label: Label("Maintenance", systemImage: "book.and.wrench.fill"), linkText: "Maintenance", color: .blue)
                        }
                        
                        categoryCardLabel(label: Label("Repairs", systemImage: "wrench.fill"), linkText: "Repairs", color: .orange)

                        categoryCardLabel(label: Label("Fill-ups", systemImage: "fuelpump.fill"), linkText: "Fill-ups", color: .mint)
                        
                        quickActionButtons
                    }
                }
                .padding(.horizontal)
                .padding(.top, 15)
            }
//            .background(Color(.systemGroupedBackground))
            .background {
                LinearGradient(colors: [Color.indigo.opacity(0.6), Color(.systemGroupedBackground), Color(.systemGroupedBackground)], startPoint: .top, endPoint: .bottom)
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()
            }
            .navigationTitle(selectedVehicle.name)
//            .toolbar {
//                ToolbarItem(placement: .topBarTrailing) {
//                    Button {
//                        // Vehicle Settings
//                    } label: {
//                        Label("Settings", systemImage: "ellipsis.circle")
//                    }
//                }
//            }
        }
        .tint(.primary)
    }
    
    func smallDashboardCard<LabelContent: View>(label: LabelContent, color: Color, primaryText: String, secondaryText: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            label
                .labelStyle(.titleOnly)
                .font(.headline)
                .foregroundStyle(color)
            
            Spacer()
            
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(primaryText)
                    .font(.title3.bold())
                
                Text(secondaryText)
                    .foregroundStyle(Color.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 15))
    }
    
    func largeDashboardCard<LabelContent: View>(label: LabelContent, color: Color, primaryText: String, secondaryText: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            label
                .labelStyle(.titleOnly)
                .font(.headline)
                .foregroundStyle(color)
            
            HStack {
                VStack(alignment: .leading) {
                    Text(primaryText)
                        .font(.title3.bold())
                    
                    Text(secondaryText)
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                }
                //
                Spacer()
                
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 5)
                    .frame(width: 40)
                    .overlay {
                        Circle()
                            .trim(from: 0, to: 0.25)
                            .stroke(Color.green, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            .rotationEffect(.degrees(-180))
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 15))
    }
    
    func categoryCardLabel<LabelContent: View>(label: LabelContent, linkText: String, color: Color) -> some View {
        LabeledContent {
            Image(systemName: "chevron.right")
                .foregroundStyle(Color.secondary.opacity(0.5))
        } label: {
            label
                .foregroundStyle(color)
        }
        .padding()
        .contentShape(RoundedRectangle(cornerRadius: 15))
        .font(.headline)
        .frame(maxHeight: .infinity)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 15))
    }
    
    private var quickActionButtons: some View {
        HStack(spacing: 5) {
            Button {
                // Add Maintenance
            } label: {
                //                                    Label("Log Maintenance", systemImage: "plus.circle.fill")
                Label("Log Maintenance", image: "book.and.wrench.fill.badge.plus")
                    .symbolRenderingMode(.hierarchical)
                    .labelStyle(.iconOnly)
                    .font(.title2)
                    .foregroundStyle(.blue)
//                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//                        .frame(width: 60, height: 60)
            }
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 15))
            
            Button {
                // Add Maintenance
            } label: {
                //                                    Label("Add Repair", systemImage: "plus.circle.fill")
                Label("Add Repair", image: "wrench.adjustable.fill.badge.plus")
                    .symbolRenderingMode(.hierarchical)
                    .labelStyle(.iconOnly)
                    .font(.title2)
                    .foregroundStyle(.orange)
//                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//                        .frame(width: 60, height: 60)
            }
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 15))
            
            Button {
                // Add Maintenance
            } label: {
                //                                    Label("Fill-up", systemImage: "plus")
                Label("Add Fill-up", image: "fuelpump.fill.badge.plus")
                    .symbolRenderingMode(.hierarchical)
                    .labelStyle(.iconOnly)
                    .font(.title2)
                    .foregroundStyle(.mint)
                    .padding(10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//                        .frame(width: 60, height: 60)
            }
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 15))
        }
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let vehicle = Vehicle(context: context)
    vehicle.name = "My Car"
    vehicle.odometer = 12345
    
    return VehicleDashboardView(selectedVehicle: vehicle)
}
