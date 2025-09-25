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
    @ObservedObject var fillup: Fillup
    
    @State private var showingEditFillup = false
    @State private var showingMoreInfo = false
    
    var body: some View {
        List {
            Section {
                LabeledContent("Fill-up Date", value: fillup.date.formatted(date: .numeric, time: .omitted))
                
                LabeledContent("Odometer") {
                    Text("\(fillup.odometer.formatted()) \(settings.distanceUnit.abbreviated)")
                }
                
                LabeledContent("\(settings.fuelEconomyUnit.volumeUnit)s of Fuel", value: fillup.volume.formatted())
                
                LabeledContent("Price per \(settings.fuelEconomyUnit.volumeUnit)", value: (fillup.pricePerUnit ?? 0).asCurrency())
            }
            
            Section {
                LabeledContent("Trip") {
                    Text("\(fillup.tripDistance.formatted()) \(settings.distanceUnit.abbreviated)")
                }
                
                LabeledContent {
                    if fillup.fuelEconomy(settings: settings) != 0 {
                        Text("\(fillup.fuelEconomy(settings: settings), specifier: "%.1f") \(settings.fuelEconomyUnit.rawValue)")
                    } else {
                        switch fillup.fillType {
                        case .fullTank:
                            Text("First Fill")
                        case .partialFill:
                            Text("Partial Fill")
                        case .missedFill:
                            Text("Missed Fill-up")
                        }
                    }
                } label: {
                    HStack {
                        Text("Fuel Economy")
                        if fillup.fuelEconomy(settings: settings) == 0 {
                            infoButton
                        }
                    }
                }
                
                LabeledContent("Total Cost", value: (fillup.totalCost ?? 0).asCurrency())
            }
            
            FormFooterView(note: fillup.note, photos: fillup.sortedPhotosArray)
        }
        .navigationTitle("Fill-up Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditFillup) {
//            EditFillupView(vehicle: vehicle, fillup: fillup)
            AddEditFillupView(fillup: fillup) {
                dismiss()
            }
        }
        .alert("Why no fuel economy?", isPresented: $showingMoreInfo) {
            Button("OK") { }
        } message: {
            Text("Fuel economy is calculated only between full tanks of fuel. Calculation will resume after your next Full Tank fill-up.")
        }
        .toolbar {
            ToolbarItem {
                Button("Edit") {
                    showingEditFillup = true
                }
            }
        }
    }
    
    // Button that launches an alert, describing why no fuel economy exists for this fill-up (if appropriate)
    private var infoButton: some View {
        Button("Learn More", systemImage: "info.circle") {
            showingMoreInfo = true
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.plain)
        .foregroundStyle(settings.accentColor(for: .fillupsTheme))
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let fillup = Fillup(context: context)
    fillup.odometer = 12345
    fillup.volume = 7.384
    fillup.pricePerUnit = 3.569
    
    return FillupDetailView(fillup: fillup)
        .environmentObject(AppSettings())
}
