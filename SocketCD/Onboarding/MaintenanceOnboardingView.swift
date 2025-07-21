//
//  MaintenanceOnboardingView.swift
//  SocketCD
//
//  Created by Justin Risner on 5/13/24.
//

import SwiftUI

struct MaintenanceOnboardingView: View {
    @EnvironmentObject var settings: AppSettings
    let vehicle: Vehicle
    let service: Service
    @Binding var showingServiceRecordTip: Bool
    
    @State private var swipeActionWidth = UIScreen.main.bounds.width / 5
    @State private var animationOffset: CGFloat = 0
    @State private var animationDelay: Double = 0.5
    @State private var viewOpacity: Double = 0.0
    
    var body: some View {
        List {
            serviceListItem
                .accessibilityLabel("Animation, demonstrating a swipe action to add a service record")
            
            tipText
        }
        .listStyle(.plain)
        .background(Color(.systemGroupedBackground))
        .opacity(viewOpacity)
    }
    
    // MARK: - Views
    
    private var serviceListItem: some View {
        Group {
            ZStack(alignment: .leading) {
                ZStack {
                    Rectangle()
                        .foregroundStyle(settings.accentColor(for: .maintenanceTheme))
                        .frame(width: swipeActionWidth)
                    
                    Image(systemName: "plus.square.on.square.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
                .offset(x: animationOffset - swipeActionWidth)
                
                ZStack {
                    Rectangle()
                        .foregroundStyle(Color(.systemGroupedBackground))
                    
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundStyle(Color(.secondarySystemGroupedBackground))
                        
                        
                        HStack {
                            Capsule()
                                .frame(width: 5, height: 40)
                                .foregroundStyle(Color.green)
                            
                            
                            serviceInfo
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(Color(.tertiaryLabel))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 15)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color(.systemGroupedBackground))
                    .padding(.vertical, 2.5)
                    .padding(.horizontal, 20)
                }
                .offset(x: animationOffset)
            }
        }
        .animation(.easeInOut.delay(animationDelay).speed(0.5), value: animationOffset)
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .onAppear {
            // Moving the animation to the main thread prevents unexpected animation on iOS 15
            DispatchQueue.main.async {
                viewOpacity = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                animationOffset = swipeActionWidth / 2
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                dismissServiceRecordTip()
            }
        }
        .onTapGesture {
            dismissServiceRecordTip()
        }
    }
    
    // Service name and relevant info
    private var serviceInfo: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(service.name)
                .font(.headline)
            
            Text("Swipe or tap to add a service record")
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
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
                    Text("Now that you have a maintenance service set up, you can add a record each time this service is completed.")
                    
                    Text("Just swipe or tap on the service above, then tap \(Image(systemName: "plus.square.on.square.fill")) to add a new record.")
                        .accessibilityElement()
                        .accessibilityLabel("Just swipe or tap on a service above, then tap Add Service Record to add a new record.")
                }
                .padding(30)
                .font(.subheadline)
                .foregroundStyle(.white)
                .accessibilityElement(children: .combine)
            }
            .padding(.top, 30)
            .listRowSeparator(.hidden)
            .listRowBackground(Color(.systemGroupedBackground))
        }
    }
    
    // MARK: - Methods
    
    // Animates from service record list animation, back to service list view
    private func dismissServiceRecordTip() {
        withAnimation(.easeInOut) {
            animationDelay = 0
            animationOffset = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut) {
                viewOpacity = 0.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showingServiceRecordTip = false
        }
    }
}

#Preview {
    MaintenanceOnboardingView(vehicle: Vehicle(context: DataController.preview.container.viewContext), service: Service(context: DataController.preview.container.viewContext), showingServiceRecordTip: .constant(false))
        .environmentObject(AppSettings())
}
