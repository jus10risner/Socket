//
//  FillTypeInfoView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/15/24.
//

import SwiftUI

struct FillTypeInfoView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Full Tank")
                                .font(.headline)
                                .foregroundStyle(settings.accentColor(for: .fillupsTheme))
                            
                            Text("Select this fill type if you have filled your fuel tank completely.")
                            
                            Text("To track fuel economy accurately, it is important to always try to use Full Tank fill-ups.")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                        }
                        .padding()
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Partial Fill")
                                .font(.headline)
                                .foregroundStyle(settings.accentColor(for: .fillupsTheme))
                            
                            Text("Select this fill type if fuel was added, but the fuel tank is not completely full.")
                            
                            Text("This fill type helps estimate your average fuel economy. To resume detailed fuel economy tracking, add a Full Tank fill-up.")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                        }
                        .padding()
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 10) {
                            VStack(alignment: .leading) {
                                Text("Missed Fill-up")
                                    .font(.headline)
                                    .foregroundStyle(settings.accentColor(for: .fillupsTheme))
                                
                                Text("(Full Tank)")
                                    .font(.caption)
                            }
                            
                            Text("Select this fill type if you forgot to add one or more recent fill-ups to Socket.")
                            
                            Group {
                                Text("Fuel economy calculation will resume after your next Full Tank fill-up.")
                                
                                Text("**Note:** Only select this fill type if your fuel tank is full. If not, please wait until your next Full Tank fill-up to begin adding fill-ups to Socket again.")
                            }
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                        }
                        .padding()
                    }
                } header: {
                    Text("Fill Types")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .headerProminence(.increased)
            }
            .font(.subheadline)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    Button("Done", systemImage: "xmark") {
                        dismiss()
                    }
                    .labelStyle(.adaptive)
                    .adaptiveTint()
                }
            }
        }
        .interactiveDismissDisabled()
        .onAppear() {
            // Dismisses keyboard
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

#Preview {
    FillTypeInfoView()
        .environmentObject(AppSettings())
}
