//
//  FillupDetailView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import SwiftUI

struct FillupDetailView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var fillup: Fillup
    let settings = AppSettings.shared
    
    @State private var showingEditFillup = false
    @State private var showingFuelEconomyInfo = false
    
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
                    if fillup.fuelEconomy() != 0 {
                        Text("\(fillup.fuelEconomy(), specifier: "%.1f") \(settings.fuelEconomyUnit.rawValue)")
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
                        if fillup.fuelEconomy() == 0 {
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
            AddEditFillupView(fillup: fillup) {
                dismiss()
            }
        }
        .toolbar {
            ToolbarItem {
                Button("Edit") {
                    showingEditFillup = true
                }
                .adaptiveTint()
            }
        }
    }
    
    // Button that launches a popover, describing why no fuel economy exists for this fill-up
    private var infoButton: some View {
        Button("Learn More", systemImage: "info.circle") {
            showingFuelEconomyInfo = true
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
        .tint(Color.fillupsTheme)
        .popover(isPresented: $showingFuelEconomyInfo) {
            PopoverContent(text: "Fuel economy is calculated only when there are at least two Full Tank fill-ups. Partial or missed fill-ups are not included.")
        }
    }
}

#Preview {
    let context = DataController.preview.container.viewContext
    let fillup = Fillup(context: context)
    fillup.odometer = 12345
    fillup.volume = 7.384
    fillup.pricePerUnit = 3.569
    
    return FillupDetailView(fillup: fillup)
}
