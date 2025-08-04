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
    
    var body: some View {
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
        .sheet(isPresented: $showingEditCustomInfo) {
            AddEditCustomInfoView(customInfo: customInfo) {
                dismiss()
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showingEditCustomInfo = true
                }
            }
        }
    }
}

#Preview {
    CustomInfoDetailView(customInfo: CustomInfo(context: DataController.preview.container.viewContext))
}
