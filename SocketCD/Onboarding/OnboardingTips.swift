//
//  OnboardingTips.swift
//  SocketCD
//
//  Created by Justin Risner on 5/15/24.
//

import SwiftUI

struct OnboardingTips: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var settings: AppSettings
    @Binding var showingOnboardingTip: Bool
    let vehicle: Vehicle
    
    @State private var swipeActionWidth = UIScreen.main.bounds.width / 5
    @State private var animationOffset: CGFloat = 0
    @State private var animationDelay: Double = 0.5
    
    @State private var viewOpacity: Double = 0.0
    
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
        .background(Color.customBackground)
        .opacity(viewOpacity)
    }
    
    // Duplicate of first vehicle card in VehicleListView, that animates to show swiping to add a fill-up
    private var vehicleCard: some View {
        Group {
            ZStack(alignment: .leading) {
                ZStack {
                    Rectangle()
                        .foregroundStyle(Color(.defaultFillupsAccent))
                        .frame(width: swipeActionWidth)
                    
                    Image(systemName: "fuelpump.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
                .offset(x: animationOffset - swipeActionWidth)
                
                HStack(spacing: 0) {
                    Rectangle()
                        .foregroundStyle(Color(.defaultAppAccent))
                        .frame(width: swipeActionWidth / 4)
                    
                    Rectangle()
                        .foregroundStyle(Color(.red))
                        .frame(width: swipeActionWidth / 4)
                }
                .offset(x: UIScreen.main.bounds.width + animationOffset)
                
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
                                    
                                    Text("\(vehicle.odometer) \(settings.distanceUnit.abbreviated)")
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
        .animation(.easeInOut.delay(animationDelay).speed(0.75), value: animationOffset)
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .onAppear {
            animateVehicleCard()
        }
    }
    
    // Explanation text, for swiping to add a fill-up
    private var tipText: some View {
        Section {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundStyle(Color.socketPurple)
                    .accessibilityElement()
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("You can swipe on a vehicle, to quickly add fill-ups or make changes to that vehicle, right from this screen.")
                    
                    Text("When you're ready, tap your vehicle to begin adding maintenance services, repairs, and more.")
                }
                .padding(30)
                .font(.subheadline)
                .foregroundStyle(Color.white)
                .accessibilityElement(children: .combine)
            }
            .padding(.top, 30)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.customBackground)
        }
    }
    
    
    // MARK: - Methods
    
    // Animates from quick fill tip, back to vehicle list view
    private func closeOnboardingTip() {
        withAnimation(.smooth) {
            animationDelay = 0
            animationOffset = 0
        }
        
        DispatchQueue.main.async {
            viewOpacity = 0.0
            showingOnboardingTip = false
        }
    }
    
    // Animates the vehicle card, to give a peek at the swipe actions
    private func animateVehicleCard() {
        // Moving the animation to the main thread prevents unexpected animation on iOS 15
        DispatchQueue.main.async {
            viewOpacity = 1.0
        }
        
        // iOS 15's animation behavior is slower than 16+, so the timing needed to be different to get similar effects
        if #available(iOS 16, *) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.smooth) {
                    animationOffset = swipeActionWidth / 2
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
                withAnimation(.smooth) {
                    animationOffset = -swipeActionWidth / 2
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.smooth) {
                    animationOffset = 0
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    closeOnboardingTip()
                }
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.smooth) {
                    animationOffset = swipeActionWidth / 2
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation(.smooth) {
                    animationOffset = -swipeActionWidth / 2
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.smooth) {
                    animationOffset = 0
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    closeOnboardingTip()
                }
            }
        }
    }
}

#Preview {
    OnboardingTips(showingOnboardingTip: .constant(true), vehicle: Vehicle(context: DataController.preview.container.viewContext))
        .environmentObject(AppSettings())
}
