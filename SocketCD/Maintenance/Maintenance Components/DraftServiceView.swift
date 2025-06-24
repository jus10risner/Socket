//
//  DraftServiceView.swift
//  SocketCD
//
//  Created by Justin Risner on 4/5/24.
//

import SwiftUI

struct DraftServiceView: View {
    @EnvironmentObject var settings: AppSettings
    @ObservedObject var draftService: DraftService
    @Binding var selectedInterval: ServiceIntervalTypes
    let isEditView: Bool
    
    @FocusState var isInputActive: Bool
    @FocusState var fieldInFocus: Bool
    
    var body: some View {
        serviceForm
    }
    
    
    // MARK: - Views
    
    private var serviceForm: some View {
        Form {
            Section {
                TextField("Service Name (e.g. Oil Change)", text: $draftService.name)
                    .textInputAutocapitalization(.words)
                    .focused($fieldInFocus)
                    .onAppear {
                        if isEditView == false {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                                fieldInFocus = true
                            }
                        }
                    }
            }
            .focused($isInputActive)
            
            Section(footer: Text("Check your owner's manual for recommended service intervals.")) {
                VStack(alignment: .leading, spacing: 15) {
                    Text("What determines when this service is due?")
                        .font(.subheadline.bold())
                    
                    Picker("Track service by", selection: $selectedInterval) {
                        ForEach(ServiceIntervalTypes.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.vertical, 5)
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("This service should be performed every:")
                        .font(.subheadline.bold())
                    
                    Group {
                        switch selectedInterval {
                        case .distance:
                            HStack {
                                TextField("5,000", value: $draftService.distanceInterval, format: .number.decimalSeparator(strategy: .automatic))
                                    .fixedSize()
                                Text(settings.shortenedDistanceUnit)
                            }
                        case .time:
                            HStack {
                                TextField("6", value: $draftService.timeInterval, format: .number)
                                    .fixedSize()
                                
                                MonthsYearsToggle(monthsInterval: $draftService.monthsInterval, timeInterval: Int(draftService.timeInterval ?? 0))
                            }
                        case .both:
                            VStack(alignment: .leading) {
                                HStack {
                                    TextField("5,000", value: $draftService.distanceInterval, format: .number.decimalSeparator(strategy: .automatic))
                                        .fixedSize()
                                    Text("\(settings.shortenedDistanceUnit) or")
                                    TextField("6", value: $draftService.timeInterval, format: .number)
                                        .fixedSize()
                                    
                                    MonthsYearsToggle(monthsInterval: $draftService.monthsInterval, timeInterval: Int(draftService.timeInterval ?? 0))
                                }
                            }
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                }
                .padding(.vertical, 5)
            }
            .focused($isInputActive)
           
            Section(header: Text("Service Note (optional)"), footer: Text("Add info that you want to reference each time this service is performed (e.g. oil type, filter number)")) {
                TextEditor(text: $draftService.serviceNote)
                    .frame(minHeight: 50)
                    .focused($isInputActive)
            }
            
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

#Preview {
    DraftServiceView(draftService: DraftService(), selectedInterval: .constant(.distance), isEditView: true)
        .environmentObject(AppSettings())
}
