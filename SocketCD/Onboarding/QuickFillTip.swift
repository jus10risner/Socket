//
//  QuickFillTip.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import SwiftUI

struct QuickFillTip: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var settings: AppSettings
    @Binding var showingQuickFillTip: Bool
    let vehicle: Vehicle
    
    @State private var swipeActionWidth = UIScreen.main.bounds.width / 5
    @State private var animationOffset: CGFloat = 0
    @State private var animationDelay: Double = 1
    
    @State private var viewOpacity: Double = 0.0
    @State private var tipOpacity: Double = 0.0
    
    @State private var quickFillupVehicle = false
    
    var body: some View {
        quickFillView
    }
    
    // MARK: - Views
    
    private var quickFillView: some View {
        List {
            vehicleCard
                .accessibilityLabel("Animation, demonstrating a swipe action to add fill-up")
            
            tipText
        }
        .listStyle(.plain)
        .background(Color.customBackground.opacity(viewOpacity))
        .sheet(isPresented: $quickFillupVehicle, onDismiss: { closeQuickFillTip() }) {
            AddFillupView(vehicle: vehicle, quickFill: true)
                .conditionalTint(Color.selectedColor(for: .fillupsTheme))
        }
    }
    
    // Duplicate of first vehicle card in VehicleListView, that animates to show swiping to add a fill-up
    private var vehicleCard: some View {
        Group {
            ZStack(alignment: .leading) {
                ZStack {
                    Rectangle()
                        .foregroundStyle(Color.selectedColor(for: .fillupsTheme))
                        .frame(width: swipeActionWidth)
                    
                    Image(systemName: "fuelpump.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
                .offset(x: animationOffset - swipeActionWidth)
                .onTapGesture {
                    quickFillupVehicle = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        viewOpacity = 0.0
                        tipOpacity = 0.0
                        
                        withAnimation {
                            animationOffset = 0
                        }
                    }
                }
                
                ZStack {
                    Rectangle()
                        .foregroundStyle(Color(.customBackground))
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 15)
                            .colorSchemeBackground(colorScheme: colorScheme)
                            .shadow(color: .secondary.opacity(0.4), radius: colorScheme == .dark ? 0 : 2)
                        //
                        VStack(alignment: .leading, spacing: 0) {
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundStyle(Color.clear)
                                .aspectRatio(2, contentMode: .fit)
                                .overlay(
                                    ZStack {
                                        if let carPhoto = vehicle.photo {
                                            VehiclePhotoView(carPhoto: carPhoto)
                                        } else {
                                            PlaceholderPhotoView(backgroundColor: vehicle.backgroundColor)
                                        }
                                        
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(.black.opacity(0.3), lineWidth: 0.5)
                                            .foregroundStyle(Color.clear)
                                    }
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding([.top, .horizontal], 5)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(vehicle.name)
                                        .font(.headline)
                                        .lineLimit(1)
                                    
                                    Text("\(vehicle.odometer) \(settings.shortenedDistanceUnit)")
                                        .font(.caption)
                                        .foregroundStyle(Color.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "ellipsis")
                                    .foregroundStyle(Color.secondary)
                            }
                            .padding(.vertical, 7)
                            .padding(.horizontal, 15)
                        }
                    }
                    .padding(EdgeInsets(top: 5, leading: 15, bottom: 5, trailing: 15))
                    .fixedSize(horizontal: false, vertical: true)
                }
                .offset(x: animationOffset)
            }
        }
        .animation(.easeInOut.delay(animationDelay).repeatForever().speed(0.5), value: animationOffset)
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .onAppear {
            // Moving the animation to the main thread prevents unexpected animation on iOS 15
            DispatchQueue.main.async {
                withAnimation(.default.delay(0.2)) {
                    viewOpacity = 1.0
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                withAnimation(.linear(duration: 0.5)) {
                    tipOpacity = 1.0
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                animationOffset = swipeActionWidth
            }
        }
        .onTapGesture {
            closeQuickFillTip()
        }
    }
    
    // Explanation text, for swiping to add a fill-up
    private var tipText: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .foregroundStyle(Color.socketPurple)
            
            Group {
                HStack {
                    Text("Save time (and taps) by swiping to quickly add a Fill-up")
                        .font(.subheadline)
                        .padding(20)
                    
                    Spacer()
                }
                
                VStack {
                    HStack {
                        Spacer()
                        
                        Button {
                            closeQuickFillTip()
                        } label: {
                            Image(systemName: "xmark")
                                .accessibilityLabel("Dismiss Tip")
                        }
                        .buttonStyle(.plain)
                        .padding(10)
                    }
                    
                    Spacer()
                }
            }
            .foregroundStyle(Color.white)
        }
        .opacity(tipOpacity)
        .animation(nil, value: tipOpacity)
        .padding(EdgeInsets(top: 20, leading: 15, bottom: 5, trailing: 15))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
    
    
    // MARK: - Methods
    
    // Animates from quick fill tip, back to vehicle list view
    private func closeQuickFillTip() {
        tipOpacity = 0.0
        
        withAnimation {
            animationDelay = 0
            animationOffset = 0
        }
        
        withAnimation(.default.delay(0.2)) {
            viewOpacity = 0.0
        }
        
        withAnimation(.default.delay(0.5)) {
            showingQuickFillTip = false
        }
    }
}

#Preview {
    QuickFillTip(showingQuickFillTip: .constant(true), vehicle: Vehicle(context: DataController.preview.container.viewContext))
        .environmentObject(AppSettings())
}
