//
//  AddVehicleView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/13/24.
//

import SwiftUI

struct AddVehicleView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.managedObjectContext) var context
    @Environment(\.dismiss) var dismiss
    @StateObject var draftVehicle = DraftVehicle()
    
    init() {
        _draftVehicle = StateObject(wrappedValue: DraftVehicle())
    }
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Vehicle.displayOrder, ascending: true)]) var vehicles: FetchedResults<Vehicle>
    
    @FocusState var focusedField: FocusedField?
    
    @State private var selectedTab = 1
    @State private var showingDuplicateNameError = false
    
    var body: some View {
        addVehicleFlow
    }
    
    
    // MARK: - Views
    
    private var addVehicleFlow: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                vehicleNameAndOdometer
                
                vehicleImage
            }
            .ignoresSafeArea(.keyboard)
            .padding([.horizontal, .top], 30)
            .tabViewStyle(.page(indexDisplayMode: .never))
            .navigationTitle("New Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if selectedTab == 1 {
                        Button("Cancel", role: .cancel) { dismiss() }
                    } else {
                        Button {
                            withAnimation {
                                selectedTab = 1
                            }
                        } label: {
                            Label("Back", systemImage: "chevron.backward")
                        }
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    if selectedTab == 1 {
                        Button("Continue") {
                            if vehicles.contains(where: { vehicle in vehicle.name == draftVehicle.name }) {
                                showingDuplicateNameError = true
                            } else {
                                withAnimation {
                                    selectedTab = 2
                                }
                            }
                        }
                        .disabled(draftVehicle.canBeSaved ? false : true)
                    } else {
                        Button("Add") {
                            addNewVehicle()
                        }
                    }
                }
            }
            .alert("You already have a vehicle with that name", isPresented: $showingDuplicateNameError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please choose a different name.")
            }
        }
        .tint(settings.accentColor(for: .appTheme))
    }
    
    // Form where users enter a name for the vehicle, and an odometer reading
    private var vehicleNameAndOdometer: some View {
        VStack(spacing: 40) {
            Text("First, give your vehicle a name and enter the current odometer reading.")
                .font(.subheadline.bold())
            
            VStack {
                TextField("Vehicle Name", text: $draftVehicle.name)
                    .padding(7)
                    .background(RoundedRectangle(cornerRadius: 5).foregroundStyle(Color(.secondarySystemBackground)))
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .vehicleName)
                    .onSubmit {
                        focusedField = .vehicleOdometer
                    }
                    .submitLabel(.next)
                
                TextField("Odometer", value: $draftVehicle.odometer, format: .number.decimalSeparator(strategy: .automatic))
                    .padding(7)
                    .background(RoundedRectangle(cornerRadius: 5).foregroundStyle(Color(.secondarySystemBackground)))
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .vehicleOdometer)
            }
            .multilineTextAlignment(.center)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                    focusedField = .vehicleName
                }
            }
            
            Spacer()
        }
        .tag(1)
        // disables swiping to vehicleRepresentation tab
        .contentShape(Rectangle()).gesture(DragGesture())
        .onTapGesture() {
            // Dismisses keyboard when tapping anywhere outside of a text field
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    // Form where users select an image or color, to represent the vehicle
    private var vehicleImage: some View {
        VStack(spacing: 40) {
            Text("Now select an image or color to represent your vehicle. You can change this later.")
                .font(.subheadline.bold())
            
            VStack {
                AddEditVehicleImageView(draftVehicle: draftVehicle)
                    .padding(.horizontal, 5)
                
                VehiclePhotoCustomizationButtons(carPhoto: $draftVehicle.photo, selectedColor: $draftVehicle.selectedColor)
            }
            
            Spacer()
        }
        .tag(2)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                focusedField = nil
            }
        }
    }
    
    
    // MARK: - Computed Properties
    
    // Assigns a display order for the vehicle being created, so it appears below any existing vehicles in the vehicle list
    private var newVehicleDisplayOrder: Int64 {
        var displayOrderArray: [Int64] = [].sorted()
        
        for vehicle in vehicles {
            displayOrderArray.append(vehicle.displayOrder)
        }
        
        if displayOrderArray.count > 0 {
            return displayOrderArray.last! + 1
        } else {
            return 0
        }
    }
    
    
    // MARK: - Methods
    
    // Creates a new vehicle object, using the information from this view
    func addNewVehicle() {
        let colorComponents = UIColor(draftVehicle.selectedColor).cgColor.components
        
        let newVehicle = Vehicle(context: context)
        newVehicle.id = UUID()
        newVehicle.name = draftVehicle.name
        newVehicle.odometer = draftVehicle.odometer ?? 0
        newVehicle.colorComponents = colorComponents
        newVehicle.photo = draftVehicle.photo
        newVehicle.displayOrder = newVehicleDisplayOrder
        
        try? context.save()
        dismiss()
    }
}

#Preview {
    AddVehicleView()
        .environmentObject(AppSettings())
}
