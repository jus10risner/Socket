//
//  FillupDetailView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import SwiftUI

struct FillupDetailView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) var dismiss
    @ObservedObject var vehicle: Vehicle
    @ObservedObject var fillup: Fillup
    
    @State private var showingEditFillup = false
    @State private var showingMoreInfo = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        fillupDetails
    }
    
    
    // MARK: - Views
    
    private var fillupDetails: some View {
        List {
            Section {
                Text("Fill-up Date")
                    .badge(fillup.date.formatted(date: .numeric, time: .omitted))
                
                Text("Odometer")
                    .badge("\(fillup.odometer.formatted()) \(settings.shortenedDistanceUnit)")
                
                Text("\(volumeUnit)s of Fuel")
                    .badge(fillup.volume.formatted())
                
                Text("Price per \(volumeUnit)")
                    .badge((fillup.pricePerUnit ?? 0).formatted(.currency(code: Locale.current.currency?.identifier ?? "USD").precision(.fractionLength(2...))))
            }
            
            Section {
                Text("Trip")
                    .badge("\(fillup.tripDistance.formatted()) \(settings.shortenedDistanceUnit)")
                
                HStack {
                    Text("Fuel Economy")
                    if fillup.fuelEconomy == 0 {
                        infoButton
                    }
                    
                    Spacer()
                    
                    if fillup.fuelEconomy != 0 {
                        Text("\(fillup.fuelEconomy, specifier: "%.1f") \(settings.fuelEconomyUnit.rawValue)")
                            .foregroundStyle(Color.secondary)
                    } else {
                        switch fillup.fillType {
                        case .fullTank:
                            Text("First Fill")
                                .foregroundStyle(Color.secondary)
                        case .partialFill:
                            Text("Partial Fill")
                                .foregroundStyle(Color.secondary)
                        case .missedFill:
                            Text("Missed Fill-up")
                                .foregroundStyle(Color.secondary)
                        }
                    }
                }
                .accessibilityElement(children: .combine)
//
                Text("Total Cost")
                    .badge(vehicle.convertToCurrency(value: fillup.totalCost ?? 0))
            }
            
            if fillup.note != "" {
                Section("Note") {
                    Text(fillup.note)
                }
            }
            
            if !fillup.sortedPhotosArray.isEmpty {
                PhotoGridView(photos: fillup.sortedPhotosArray)
            }
        }
        .navigationTitle("Fill-up Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditFillup) {
            EditFillupView(vehicle: vehicle, fillup: fillup)
        }
        .alert("Delete Fill-up", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                fillup.delete()
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("\nDeleting fill-up records may cause inaccurate fuel economy calculation. Delete this record anyway?")
        }
        .alert("Why no fuel economy?", isPresented: $showingMoreInfo) {
            Button("OK") { }
        } message: {
            Text("\nFuel economy is calculated only between consecutive Full Tanks of fuel. The information on this screen may still be used to estimate average fuel economy for this vehicle.")
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingEditFillup = true
                    } label: {
                        Label("Edit Fill-up", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete Fill-up", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .accessibilityLabel("Fill-up Options")
                }
            }
        }
    }
    
    // Button that launches an alert, describing why no fuel economy exists for this fill-up (if appropriate)
    private var infoButton: some View {
        Button {
            showingMoreInfo = true
        } label: {
            Label("Learn More", systemImage: "info.circle")
                .labelStyle(.iconOnly)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.selectedColor(for: .fillupsTheme))
    }
    
    
    // MARK: - Computed Properties
    
    // Returns the appropriate volume unit, based on the fuel economy units selected in Settings
    private var volumeUnit: String {
        if settings.fuelEconomyUnit == .mpg {
            return "Gallon"
        } else {
            return "Liter"
        }
    }
}

#Preview {
    FillupDetailView(vehicle: Vehicle(context: DataController.preview.container.viewContext), fillup: Fillup(context: DataController.preview.container.viewContext))
        .environmentObject(AppSettings())
}
