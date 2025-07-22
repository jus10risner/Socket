//
//  CustomInfoDetailView.swift
//  SocketCD
//
//  Created by Justin Risner on 3/14/24.
//

import SwiftUI

struct CustomInfoDetailView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var customInfo: CustomInfo
    
    @State private var copyHint = "Tap to copy"
    
    @State private var showingEditCustomInfo = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        customInfoDetails
    }
    
    
    // MARK: - Views
    
    private var customInfoDetails: some View {
        List {
            if !customInfo.detail.isEmpty {
                Section(footer: Text(copyHint)) {
                    Text(customInfo.detail)
                        .onTapGesture {
                            let pasteBoard = UIPasteboard.general
                            pasteBoard.string = customInfo.detail
                            copyHint = "Copied!"
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copyHint = "Tap to copy" }
                        }
                }
                .textCase(nil)
            }
            
            if customInfo.note != "" {
                Section("Note") {
                    Text(customInfo.note)
                }
            }
            
            if !customInfo.sortedPhotosArray.isEmpty {
                PhotoGridView(photos: customInfo.sortedPhotosArray)
            }
        }
        .navigationTitle(customInfo.label)
//        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditCustomInfo) { EditCustomInfoView(customInfo: customInfo) }
        .alert("Delete Vehicle Info", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                DataController.shared.delete(customInfo)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("\nPermanently delete \(customInfo.label)? This cannot be undone.")
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingEditCustomInfo = true
                    } label: {
                        Label("Edit Info", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete Info", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}

#Preview {
    CustomInfoDetailView(customInfo: CustomInfo(context: DataController.preview.container.viewContext))
}
